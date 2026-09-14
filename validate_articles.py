#!/usr/bin/env python3
"""
Validate articles in articlescheck.json using linkchecker
This script validates URLs to confirm articles are real and accessible
"""

import json
import subprocess
import sys
import os
from datetime import datetime

def load_articles():
    """Load articles from articlescheck.json"""
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

def validate_urls_with_linkchecker(urls):
    """Validate URLs using linkchecker command line tool"""
    results = []
    
    for i, url in enumerate(urls, 1):
        print(f"\n🔍 Validating article {i}: {url}")
        
        # Run linkchecker to check the URL
        try:
            # Use linkchecker with --quiet flag to reduce output
            cmd = ['linkchecker', '--quiet', '--check-external', '--mode', 'strict', url]
            
            process = subprocess.run(
                cmd, 
                capture_output=True, 
                text=True, 
                timeout=30
            )
            
            # Parse linkchecker output to determine status
            if process.returncode == 0:
                status = "✅ VALID"
                credibility_impact = "+1 rating"
                notes = "URL accessible and content found"
            else:
                # Check for specific error patterns
                output_lower = process.stdout.lower() + process.stderr.lower()
                if 'connection refused' in output_lower or 'timeout' in output_lower:
                    status = "❌ CONNECTION ERROR"
                    credibility_impact = "-1 rating"
                    notes = "URL unreachable or timeout"
                elif '404' in output_lower or 'not found' in output_lower:
                    status = "❌ DEAD LINK"
                    credibility_impact = "-2 rating"
                    notes = "Page not found (404 error)"
                elif 'forbidden' in output_lower or 'access denied' in output_lower:
                    status = "⚠️ ACCESS DENIED"
                    credibility_impact = "-1 rating"
                    notes = "Access restricted or requires authentication"
                else:
                    status = "⚠️ UNKNOWN ERROR"
                    credibility_impact = "-1 rating"
                    notes = f"LinkChecker output: {process.stdout[:200]}..."
            
            results.append({
                'url': url,
                'status': status,
                'credibility_impact': credibility_impact,
                'notes': notes,
                'linkchecker_output': process.stdout[:500] + '...' if len(process.stdout) > 500 else process.stdout
            })
            
        except subprocess.TimeoutExpired:
            results.append({
                'url': url,
                'status': "⏰ TIMEOUT",
                'credibility_impact': "-2 rating",
                'notes': "URL validation timed out after 30 seconds",
                'linkchecker_output': "Timeout occurred"
            })
        except Exception as e:
            results.append({
                'url': url,
                'status': "💥 ERROR",
                'credibility_impact': "-2 rating",
                'notes': f"Validation error: {str(e)}",
                'linkchecker_output': "System error during validation"
            })
    
    return results

def display_results(original_articles, validation_results):
    """Display validation results"""
    print("\n" + "="*80)
    print("ARTICLE VALIDATION RESULTS")
    print("="*80)
    
    total_articles = len(original_articles)
    valid_count = sum(1 for r in validation_results if r['status'].startswith('✅'))
    invalid_count = sum(1 for r in validation_results if r['status'].startswith(('❌', '⚠️')))
    
    print(f"📊 Summary: {total_articles} articles checked")
    print(f"✅ Valid: {valid_count}")
    print(f"❌ Invalid: {invalid_count}")
    print(f"📈 Validity Rate: {(valid_count/total_articles)*100:.1f}%")
    
    print("\n" + "-"*80)
    print("DETAILED RESULTS")
    print("-"*80)
    
    for i, (article, result) in enumerate(zip(original_articles, validation_results), 1):
        print(f"\n📄 Article {i}: {article.get('title', 'Untitled')}")
        print(f"🔗 URL: {article['link']}")
        print(f"📅 Date: {article.get('date', 'Unknown')}")
        print(f"⭐ Current Rating: {article.get('rating', 'N/A')}/5")
        
        print(f"🔍 Validation Status: {result['status']}")
        print(f"📊 Credibility Impact: {result['credibility_impact']}")
        print(f"💭 Notes: {result['notes']}")
        
        if result['linkchecker_output']:
            print(f"📝 LinkChecker Output: {result['linkchecker_output'][:200]}...")
        
        # Show recommended new rating
        current_rating = article.get('rating', 3)
        try:
            rating_change = int(result['credibility_impact'].split()[0])
            new_rating = max(1, min(5, current_rating + rating_change))
            print(f"🎯 Recommended New Rating: {new_rating}/5")
        except:
            print(f"🎯 Recommended New Rating: {current_rating}/5 (unchanged)")
        
        print("-" * 80)

def main():
    print("🚀 Starting article validation with LinkChecker...")
    print(f"⏰ Validation started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}")
    
    # Load articles
    articles = load_articles()
    if not articles:
        print("❌ No articles to validate")
        return
    
    # Extract URLs for validation
    urls = [article['link'] for article in articles if 'link' in article]
    
    if not urls:
        print("❌ No valid URLs found in articles")
        return
    
    print(f"📋 Found {len(articles)} articles with {len(urls)} URLs to validate")
    
    # Validate URLs
    validation_results = validate_urls_with_linkchecker(urls)
    
    # Display results
    display_results(articles, validation_results)
    
    # Summary for decision making
    print("\n" + "="*80)
    print("DECISION RECOMMENDATIONS")
    print("="*80)
    
    keep_articles = []
    for i, (article, result) in enumerate(zip(articles, validation_results), 1):
        current_rating = article.get('rating', 3)
        
        if result['status'].startswith('✅'):
            keep_articles.append(i)
            print(f"✅ Article {i}: KEEP (Rating: {current_rating}/5, Validated)")
        elif result['status'].startswith('⚠️'):
            print(f"⚠️  Article {i}: CONSIDER (Rating: {current_rating}/5, Issues found)")
        else:
            print(f"❌ Article {i}: REMOVE (Rating: {current_rating}/5, Critical issues)")
    
    print(f"\n📝 Keep for articlescheck.json: {len(keep_articles)}/{len(articles)} articles")
    
    if len(keep_articles) < len(articles):
        print("⚠️  Some articles failed validation. Consider updating ratings or removing invalid entries.")

if __name__ == "__main__":
    main()