#!/usr/bin/env python3
"""
OpenClaw Site Verification - Real Implementation
Uses OpenClaw's actual web_search and web_fetch tools through their proper interfaces.
"""

import json
import subprocess
import sys
import os
from datetime import datetime
from pathlib import Path

def log_message(message):
    """Log message with timestamp"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_line = f"[{timestamp}] {message}"
    print(log_line)
    # Write to log file
    log_file = "/var/log/openclaw_verification.log"
    with open(log_file, 'a') as f:
        f.write(log_line + '\n')

def web_search_openclaw(prompt, count=10):
    """Use OpenClaw's web_search tool via exec"""
    try:
        log_message(f"Calling OpenClaw web_search with: {prompt[:50]}...")
        
        # Use exec to call web_search through OpenClaw's tool system
        # This is the proper way to call OpenClaw tools
        cmd = f"python3 -c \"
import json
import sys
sys.path.append('/root/.openclaw/workspace')

# Import the web_search tool from OpenClaw's tools
from tools import web_search

# Call the actual web_search tool
result = web_search(query='{prompt}', count={count})
print(json.dumps(result))
\""
        
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            search_data = json.loads(result.stdout)
            log_message(f"web_search returned {len(search_data.get('results', []))} results")
            return search_data
        else:
            log_message(f"web_search failed: {result.stderr}")
            return None
            
    except Exception as e:
        log_message(f"web_search exception: {e}")
        return None

def web_fetch_openclaw(url, extractMode="text", maxChars=5000):
    """Use OpenClaw's web_fetch tool via exec"""
    try:
        log_message(f"Fetching content from: {url}")
        
        # Use exec to call web_fetch through OpenClaw's tool system
        cmd = f"python3 -c \"
import json
import sys
sys.path.append('/root/.openclaw/workspace')

# Import the web_fetch tool from OpenClaw's tools
from tools import web_fetch

# Call the actual web_fetch tool
result = web_fetch(url='{url}', extractMode='{extractMode}', maxChars={maxChars})
print(json.dumps(result))
\""
        
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            fetch_data = json.loads(result.stdout)
            status = fetch_data.get("status", 0)
            if status == 200:
                log_message(f"Successfully fetched content from {url} ({len(fetch_data.get('text', ''))} chars)")
            else:
                log_message(f"Failed to fetch {url}: status {status}")
            return fetch_data
        else:
            log_message(f"web_fetch failed: {result.stderr}")
            return None
            
    except Exception as e:
        log_message(f"web_fetch exception: {e}")
        return None

def validate_urls_reachability(urls):
    """Validate HTTP status codes using curl"""
    valid_urls = []
    
    log_message(f"Checking network reachability for {len(urls)} URLs...")
    
    for url in urls:
        try:
            # Use curl to check HTTP status code
            cmd = [
                'curl', '-o', '/dev/null', '-s', '-w', '%{http_code}',
                '-L', '--max-redirs', '3', '--max-time', '5', url
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            http_code = result.stdout.strip()
            
            if http_code in ['200', '301', '302']:
                valid_urls.append(url)
                log_message(f"  [PASS] {http_code} -> {url}")
            else:
                log_message(f"  [FAIL] {http_code} -> {url}")
                
        except Exception as e:
            log_message(f"  [ERROR] Exception checking {url}: {e}")
    
    log_message(f"{len(valid_urls)}/{len(urls)} URLs returned accessible HTTP status codes.")
    return valid_urls

def main():
    """Main execution using OpenClaw's native capabilities"""
    log_message("=== Starting OpenClaw Site Verification Job ===")
    
    # Configuration
    LOG_FILE = "/var/log/openclaw_verification.log"
    WORK_DIR = f"/tmp/openclaw_verify_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    OPENCLAW_PROMPT = "Search for recent research papers on multi-agent LLM architectures and list key findings."
    
    # Create work directory
    Path(WORK_DIR).mkdir(parents=True, exist_ok=True)
    
    # Step 1: Use OpenClaw's web_search capability
    log_message("Step 1: Using OpenClaw web_search capability...")
    
    search_result = web_search_openclaw(OPENCLAW_PROMPT, count=10)
    
    if search_result and "results" in search_result:
        # Extract URLs from search results
        urls = []
        for result in search_result["results"]:
            if "url" in result:
                urls.append(result["url"])
        
        # Remove duplicates and filter valid URLs
        unique_urls = []
        for url in urls:
            if url and url.startswith(('http://', 'https://')) and url not in unique_urls:
                unique_urls.append(url)
        
        url_count = len(unique_urls)
        log_message(f"Extracted {url_count} unique URL(s) to test.")
        
        # Write URLs to file for reference
        target_urls_file = os.path.join(WORK_DIR, "target_urls.txt")
        with open(target_urls_file, 'w') as f:
            for url in unique_urls:
                f.write(f"{url}\n")
        
        if url_count == 0:
            log_message("No URLs extracted from search. Exiting.")
            return
        
    else:
        log_message("No results from web_search. Exiting.")
        return
    
    # Step 2: Validate HTTP Status Code & Network Connectivity
    log_message("Step 2: Checking network reachability and HTTP status codes...")
    
    real_sites_file = os.path.join(WORK_DIR, "real_sites.txt")
    valid_urls = validate_urls_reachability(unique_urls)
    
    if not valid_urls:
        log_message("No reachable sites found. Exiting.")
        return
    
    # Write valid URLs to file
    with open(real_sites_file, 'w') as f:
        for url in valid_urls:
            f.write(f"{url}\n")
    
    # Step 3: Use OpenClaw's web_fetch capability
    log_message("Step 3: Using OpenClaw web_fetch capability...")
    
    verified_sites = []
    content_analysis_file = os.path.join(WORK_DIR, "content_analysis.txt")
    
    with open(content_analysis_file, 'w') as analysis_file:
        for url in valid_urls:
            log_message(f"Fetching content from: {url}")
            
            fetch_result = web_fetch_openclaw(url, extractMode="text", maxChars=5000)
            
            if fetch_result and fetch_result.get("status") == 200:
                content = fetch_result.get("text", "")
                analysis_file.write(f"=== {url} ===\n")
                analysis_file.write(f"Status: OK\n")
                analysis_file.write(f"Content length: {len(content)} characters\n")
                analysis_file.write(f"Extractor: {fetch_result.get('extractor', 'unknown')}\n")
                
                # Simple legitimacy check based on content
                if len(content) > 100 and "error" not in content.lower():
                    analysis_file.write("Legitimacy: PASS - Contains substantial content\n")
                    verified_sites.append(url)
                else:
                    analysis_file.write("Legitimacy: FAIL - Insufficient or problematic content\n")
            else:
                error_msg = fetch_result.get("error", "Unknown error") if fetch_result else "No fetch result"
                analysis_file.write(f"=== {url} ===\n")
                analysis_file.write(f"Status: FAIL - {error_msg}\n")
    
    final_count = len(verified_sites)
    log_message(f"Content verification completed: {final_count}/{len(valid_urls)} sites are legitimate and contain sufficient content.")
    
    # Store verification summary
    verification_summary = {
        "total_urls": url_count,
        "reachable_urls": len(valid_urls),
        "verified_sites": final_count,
        "work_dir": WORK_DIR,
        "verified_urls": verified_sites,
        "prompt": OPENCLAW_PROMPT,
        "status": "completed",
        "method": "native_openclaw_tools"
    }
    
    summary_file = os.path.join(WORK_DIR, "verification_summary.json")
    with open(summary_file, 'w') as f:
        json.dump(verification_summary, f, indent=2)
    
    log_message("Verification summary:")
    log_message(f"  Total URLs found: {url_count}")
    log_message(f"  Reachable URLs: {len(valid_urls)}")
    log_message(f"  Verified sites: {final_count}")
    log_message(f"  Results stored in: {WORK_DIR}")
    
    log_message("=== OpenClaw Site Verification Job Complete ===")

if __name__ == "__main__":
    main()