#!/usr/bin/env python3
"""
Validate new AV articles using linkchecker
This script validates URLs to confirm new articles are real before adding to articlescheck.json
"""

import json
import subprocess
import sys
import os
from datetime import datetime

def load_existing_articles():
    """Load existing articles from articlescheck.json"""
    try:
        with open('/root/.openclaw/workspace/innovateav/articlescheck.json', 'r') as f:
            articles = json.load(f)
        return articles
    except FileNotFoundError:
        print("❌ articlescheck.json not found")
        return []
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing JSON: {e}")
        return []

def validate_url_with_linkchecker(url):
    """Validate a single URL using linkchecker"""
    try:
        # Use linkchecker to check the URL
        cmd = ['linkchecker', '--quiet', '--check-external', '--mode', 'strict', url]
        
        process = subprocess.run(
            cmd, 
            capture_output=True, 
            text=True, 
            timeout=30
        )
        
        output_lower = process.stdout.lower() + process.stderr.lower()
        
        # Check for specific error conditions
        if '402' in output_lower or 'unauthorized' in output_lower:
            return '❌ 402 UNAUTHORIZED', -2, "Access unauthorized (402 error)"
        elif '404' in output_lower or 'not found' in output_lower:
            return '❌ 404 NOT FOUND', -2, "Page not found (404 error)"
        elif 'connection refused' in output_lower:
            return '❌ CONNECTION REFUSED', -1, "Connection refused"
        elif 'timeout' in output_lower:
            return '❌ TIMEOUT', -1, "Connection timeout"
        elif 'forbidden' in output_lower or 'access denied' in output_lower:
            return '❌ ACCESS DENIED', -1, "Access denied or forbidden"
        elif process.returncode == 0:
            return '✅ VALID', 0, "URL accessible and content found"
        else:
            return '⚠️ UNKNOWN ERROR', -1, f"LinkChecker returned error: {process.stdout[:200]}..."
        
    except subprocess.TimeoutExpired:
        return '⏰ TIMEOUT', -2, "Validation timed out after 30 seconds"
    except Exception as e:
        return '💥 ERROR', -2, f"Validation error: {str(e)}"

def search_for_new_articles():
    """Search for new AV articles from recent sources"""
    # This would be the function that searches for new articles
    # For now, we'll simulate it with some example articles
    # In real implementation, this would call web_search
    
    # Mock search results - in real implementation, this would use web_search
    mock_search_results = [
        {
            "title": "Waymo Launches Autonomous Vehicle Service in Three New Metropolitan Areas",
            "link": "https://www.reuters.com/technology/waymo-expands-autonomous-vehicle-service-three-new-cities-2026-09-14",
            "date": "2026-09-14",
            "source": "mock_reuters"
        },
        {
            "title": "AMD Unveils New AI Processing Chip for Autonomous Vehicle Applications", 
            "link": "https://www.techcrunch.com/2026/09/14/amd-ai-processor-autonomous-vehicles",
            "date": "2026-09-14",
            "source": "mock_techcrunch"
        },
        {
            "title": "Nvidia Announces Breakthrough in Autonomous Vehicle Processing",
            "link": "https://venturebeat.com/2026/09/13/nvidia-breakthrough-autonomous-vehicle-ai/",
            "date": "2026-09-13",
            "source": "mock_venturebeat"
        },
        {
            "title": "Tesla Optimus Gen 3 Robotaxi Fleet Begins Operations",
            "link": "https://techcrunch.com/2026/09/12/tesla-optimus-robotaxi-fleet-operations/",
            "date": "2026-09-12",
            "source": "mock_another_techcrunch"
        },
        {
            "title": "Alphabet's Waymo Partners with Major US Cities for Autonomous Vehicle Testing",
            "link": "https://www.reuters.com/technology/alphabet-waymo-partners-us-cities-autonomous-vehicle-testing-2026-09-11",
            "date": "2026-09-11",
            "source": "mock_reuters2"
        },
        {
            "title": "Toyota Develops Advanced Sensor Fusion for Autonomous Driving",
            "link": "https://www.autonews.com/toyota-advanced-sensor-fusion-autonomous-driving-2026-09-10",
            "date": "2026-09-10",
            "source": "mock_autonews"
        },
        {
            "title": "Sony Collaborates with Cruise on Next-Gen Autonomous Vehicle Platform",
            "link": "https://venturebeat.com/2026/09/09/sony-cruise-autonomous-vehicle-platform/",
            "date": "2026-09-09",
            "source": "mock_venturebeat2"
        }
    ]
    
    return mock_search_results

def validate_and_rate_articles(new_articles):
    """Validate new articles and assign ratings"""
    validated_articles = []
    
    for article in new_articles:
        print(f"🔍 Validating: {article['title']}")
        
        # Validate URL with linkchecker
        status, credibility_impact, notes = validate_url_with_linkchecker(article['link'])
        
        # Apply rating rules
        current_rating = article.get('rating', 5)
        
        # Special rule: 402 or 404 = rating 1
        if status.startswith(('❌ 402', '❌ 404')):
            new_rating = 1
            credibility_note = " (Special rule: 402/404 = rating 1)"
        else:
            new_rating = max(1, min(5, current_rating + credibility_impact))
            credibility_note = f" (Linkchecker: {credibility_impact:+d})"
        
        validated_article = {
            "title": article["title"],
            "link": article["link"],
            "date": article["date"],
            "rating": new_rating,
            "validation_status": status,
            "validation_notes": notes + credibility_note,
            "source": article.get("source", "unknown")
        }
        
        validated_articles.append(validated_article)
        print(f"   Result: {status} → New rating: {new_rating}/5")
    
    return validated_articles

def filter_high_quality_articles(validated_articles, existing_articles):
    """Filter to keep only high-quality articles (rating 4-5)"""
    existing_links = [art.get('link') for art in existing_articles]
    
    high_quality_articles = [
        art for art in validated_articles
        if art.get('rating', 0) >= 4 
        and art['link'] not in existing_links
    ]
    
    return high_quality_articles

def save_articles_to_file(articles):
    """Save validated articles to articlescheck.json"""
    # Load existing articles
    existing_articles = load_existing_articles()
    
    # Filter out duplicates
    existing_links = [art.get('link') for art in existing_articles]
    new_articles = [
        art for art in articles 
        if art['link'] not in existing_links
    ]
    
    if not new_articles:
        print("ℹ️  No new high-quality articles to add")
        return
    
    # Combine existing and new articles
    combined_articles = existing_articles + new_articles
    
    # Sort by date (newest first) and limit to last 50 articles
    combined_articles.sort(key=lambda x: x.get('date', ''), reverse=True)
    combined_articles = combined_articles[:50]
    
    # Remove validation fields for final storage
    for article in combined_articles:
        article.pop('validation_status', None)
        article.pop('validation_notes', None)
        article.pop('source', None)
    
    # Save to file
    with open('/root/.openclaw/workspace/innovateav/articlescheck.json', 'w') as f:
        json.dump(combined_articles, f, indent=2)
    
    print(f"✅ Saved {len(new_articles)} new articles to articlescheck.json")
    print(f"📊 Total articles in file: {len(combined_articles)}")

def main():
    print("🚀 Starting AV article validation with LinkChecker...")
    print(f"⏰ Validation started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}")
    
    # Load existing articles
    existing_articles = load_existing_articles()
    print(f"📚 Existing articles in database: {len(existing_articles)}")
    
    # Search for new articles (in real implementation, this would use web_search)
    print("🔍 Searching for new AV articles...")
    new_articles = search_for_new_articles()
    print(f"📊 Found {len(new_articles)} potential new articles")
    
    # Validate and rate articles
    print("\n🔍 Validating URLs with LinkChecker...")
    validated_articles = validate_and_rate_articles(new_articles)
    
    # Display summary
    print("\n" + "="*80)
    print("VALIDATION SUMMARY")
    print("="*80)
    
    for i, article in enumerate(validated_articles, 1):
        print(f"\n📄 Article {i}: {article['title']}")
        print(f"🔗 URL: {article['link']}")
        print(f"📅 Date: {article['date']}")
        print(f"⭐ Rating: {article['rating']}/5")
        print(f"🔍 Validation: {article['validation_status']}")
        print(f"💭 Notes: {article['validation_notes']}")
    
    # Filter high-quality articles
    print(f"\n🔍 Filtering for high-quality articles (rating 4-5)...")
    high_quality_articles = filter_high_quality_articles(validated_articles, existing_articles)
    
    print(f"✅ High-quality articles to add: {len(high_quality_articles)}")
    
    # Save to file
    if high_quality_articles:
        save_articles_to_file(high_quality_articles)
    
    print(f"\n✅ Validation complete at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}")

if __name__ == "__main__":
    main()