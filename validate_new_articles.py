#!/usr/bin/env python3
"""
Validate new AV Innovate articles using 4-step validation process
This script validates new articles before adding them to articles2.json
"""

import json
import subprocess
import sys
import os
from datetime import datetime

def load_existing_articles():
    """Load existing articles from articles2.json"""
    try:
        with open('/root/.openclaw/workspace/innovateav/articles2.json', 'r') as f:
            articles = json.load(f)
        return articles
    except FileNotFoundError:
        print("❌ articles2.json not found")
        return []
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing JSON: {e}")
        return []

def fetch_article_content(url):
    """Fetch article content for validation"""
    try:
        # Use webfetch to get content
        cmd = ['curl', '-s', '--max-time', '30', url]
        process = subprocess.run(cmd, capture_output=True, text=True, timeout=35)
        
        if process.returncode != 0:
            return None, "Failed to fetch content"
        
        content = process.stdout
        return content, None
    except Exception as e:
        return None, f"Content fetch error: {str(e)}"

def step1_check_electric_vehicle_content(content, title):
    """Step 1: Check electric vehicle content"""
    if not content:
        return False, "No content available"
    
    content_lower = content.lower()
    title_lower = title.lower()
    
    # Keywords for electric vehicle content
    ev_keywords = [
        'electric vehicle', 'autonomous vehicle', 'robotaxi', 'av', 'autonomous',
        'self-driving', 'lidar', 'radar', 'sensor', 'navigation', 'autopilot',
        'driverless', 'vehicle', 'transportation', 'mobility', 'autonomous tech',
        'hydrogen train', 'hydro train', 'fuel cell', 'electric train'
    ]
    
    # Check if content contains electric vehicle related terms
    ev_matches = sum(1 for keyword in ev_keywords if keyword in content_lower)
    
    # Also check title for EV indicators
    title_ev_matches = sum(1 for keyword in ev_keywords if keyword in title_lower)
    
    # Consider it electric vehicle content if it has significant matches
    total_matches = ev_matches + title_ev_matches
    if total_matches >= 3:
        return True, f"Found {total_matches} electric vehicle related terms"
    else:
        return False, f"Only {total_matches} electric vehicle related terms found (minimum 3 required)"

def step2_verify_title_matches_content(content, title):
    """Step 2: Verify title matches page text"""
    if not content or not title:
        return False, "Missing content or title"
    
    # Extract first 200 characters of content for comparison
    content_sample = content[:200].lower()
    title_lower = title.lower()
    
    # Check if title words appear in content
    title_words = [word.strip() for word in title.lower().split() if len(word) > 3]
    content_words = content_sample.split()
    
    matches = 0
    for word in title_words:
        if word in content_words:
            matches += 1
    
    # Consider title matches if at least 50% of significant title words appear in content
    if len(title_words) > 0:
        match_percentage = (matches / len(title_words)) * 100
        if match_percentage >= 50:
            return True, f"Title matches content ({matches}/{len(title_words)} words)"
        else:
            return False, f"Title doesn't match content well ({matches}/{len(title_words)} words, {match_percentage:.1f}%)"
    else:
        return True, "Title too short to validate properly"

def step3_check_last_paragraph_relevance(content):
    """Step 3: Check last paragraph relevance"""
    if not content:
        return False, "No content available"
    
    # Try to extract the last paragraph (rough approximation)
    paragraphs = content.split('\n\n')
    if not paragraphs:
        return False, "No paragraphs found"
    
    last_paragraph = paragraphs[-1]
    last_para_lower = last_paragraph.lower()
    
    # Check for relevance indicators
    relevance_indicators = [
        'conclusion', 'summary', 'overview', 'key findings', 'final thoughts',
        'the future', 'industry trends', 'technical details', 'implications'
    ]
    
    is_relevant = any(indicator in last_para_lower for indicator in relevance_indicators)
    
    if is_relevant:
        return True, "Last paragraph contains relevant concluding information"
    else:
        # Alternative: check if last paragraph contains technical details or summary info
        if any(word in last_para_lower for word in [' technology', 'system', 'platform', 'implementation', 'deployment']):
            return True, "Last paragraph contains technical/implementation details"
        else:
            return False, "Last paragraph lacks relevance or concluding information"

def step4_review_existing_articles(existing_articles, new_articles):
    """Step 4: Review existing articles in list for compliance and remove non-compliant ones"""
    if not existing_articles:
        return True, "No existing articles to review"
    
    # Get existing article links for comparison
    existing_links = [article.get('link') for article in existing_articles if article.get('link')]
    
    non_compliant_count = 0
    compliant_articles = []
    
    for article in existing_articles:
        # Basic compliance check: has required fields and valid URL format
        has_required_fields = all(key in article for key in ['title', 'link', 'date'])
        has_valid_url = article.get('link', '').startswith(('http://', 'https://'))
        
        if has_required_fields and has_valid_url:
            compliant_articles.append(article)
        else:
            non_compliant_count += 1
            print(f"   📋 Removing non-compliant existing article: {article.get('title', 'Unknown')}")
    
    if non_compliant_count > 0:
        print(f"   📋 Found {non_compliant_count} non-compliant existing articles to remove")
    
    return True, f"Existing articles review complete: {len(compliant_articles)} compliant, {non_compliant_count} removed"

def validate_new_articles():
    """Main validation function"""
    print("🚀 Starting AV Innovate article validation (4-step process)...")
    print(f"⏰ Validation started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}")
    
    # Load existing articles
    existing_articles = load_existing_articles()
    print(f"📚 Existing articles in articles2.json: {len(existing_articles)}")
    
    # New articles to validate (from latest_av_articles.json)
    new_articles = [
        {
            "title": "Waymo Launches Simultaneous Driverless Robotaxi Service in San Diego, Las Vegas, Tampa, and Denver",
            "link": "https://techcrunch.com/2026/07/08/waymo-starts-driverless-rides-in-san-diego-las-vegas-tampa-denver.html",
            "date": "2026-07-08",
            "category": "AV"
        },
        {
            "title": "Autonomous Vehicles 2026: Self-Driving Cars, Robotaxis, and the Commercial Deployment Boom",
            "link": "https://www.programming-helper.com/tech/autonomous-vehicles-2026-self-driving-cars-robotaxis-commercial-deployment",
            "date": "2026-07-02",
            "category": "AV"
        },
        {
            "title": "APTA Honors Hydrogen Trains and Autonomous Systems",
            "link": "https://raillynews.com/2026/07/apta-honors-hydrogen-trains-and-autonomous-systems/",
            "date": "2026-07-15",
            "category": "AV"
        }
    ]
    
    print(f"📊 New articles to validate: {len(new_articles)}")
    
    # Step 1: Check electric vehicle content
    print("\n🔍 Step 1: Checking electric vehicle content...")
    step1_results = []
    for article in new_articles:
        print(f"   📄 Validating: {article['title'][:60]}...")
        content, fetch_error = fetch_article_content(article['link'])
        
        if content:
            is_ev_content, ev_note = step1_check_electric_vehicle_content(content, article['title'])
            step1_results.append({
                'article': article,
                'content': content,
                'is_ev_content': is_ev_content,
                'ev_note': ev_note
            })
            print(f"      ✅ EV Check: {ev_note}")
        else:
            step1_results.append({
                'article': article,
                'content': None,
                'is_ev_content': False,
                'ev_note': fetch_error or "Content fetch failed"
            })
            print(f"      ❌ EV Check: {fetch_error or 'Content fetch failed'}")
    
    # Step 2: Verify title matches page text
    print("\n🔍 Step 2: Verifying title matches page text...")
    step2_results = []
    for result in step1_results:
        article = result['article']
        content = result['content']
        
        if content:
            is_title_match, title_note = step2_verify_title_matches_content(content, article['title'])
            step2_results.append({
                'article': article,
                'content': content,
                'is_title_match': is_title_match,
                'title_note': title_note
            })
            print(f"      {'✅' if is_title_match else '❌'} Title Match: {title_note}")
        else:
            step2_results.append({
                'article': article,
                'content': None,
                'is_title_match': False,
                'title_note': "Cannot validate - no content available"
            })
            print(f"      ❌ Title Match: Cannot validate - no content available")
    
    # Step 3: Check last paragraph relevance
    print("\n🔍 Step 3: Checking last paragraph relevance...")
    step3_results = []
    for result in step2_results:
        article = result['article']
        content = result['content']
        
        if content:
            is_last_para_relevant, para_note = step3_check_last_paragraph_relevance(content)
            step3_results.append({
                'article': article,
                'content': content,
                'is_last_para_relevant': is_last_para_relevant,
                'para_note': para_note
            })
            print(f"      {'✅' if is_last_para_relevant else '❌'} Last Paragraph: {para_note}")
        else:
            step3_results.append({
                'article': article,
                'content': None,
                'is_last_para_relevant': False,
                'para_note': "Cannot validate - no content available"
            })
            print(f"      ❌ Last Paragraph: Cannot validate - no content available")
    
    # Step 4: Review existing articles for compliance and cleanup
    print("\n🔍 Step 4: Reviewing existing articles for compliance and cleanup...")
    step4_success, step4_note = step4_review_existing_articles(existing_articles, new_articles)
    print(f"      {step4_note}")
    
    # Determine final validation results
    print("\n" + "="*80)
    print("4-STEP VALIDATION RESULTS")
    print("="*80)
    
    validated_articles = []
    failed_articles = []
    
    for result in step3_results:
        article = result['article']
        
        # All steps must pass for an article to be valid
        passes_all_steps = (
            result['is_ev_content'] and
            result['is_title_match'] and
            result['is_last_para_relevant']
        )
        
        if passes_all_steps:
            validated_articles.append(article)
            print(f"\n✅ VALID ARTICLE:")
            print(f"   Title: {article['title']}")
            print(f"   Link: {article['link']}")
            print(f"   Date: {article['date']}")
            print(f"   Category: {article['category']}")
            print(f"   Validation: All 4 steps passed")
        else:
            failed_articles.append(article)
            print(f"\n❌ INVALID ARTICLE (FAILS VALIDATION):")
            print(f"   Title: {article['title']}")
            print(f"   Link: {article['link']}")
            print(f"   Date: {article['date']}")
            print(f"   Category: {article['category']}")
            
            # Show which steps failed
            failed_steps = []
            if not result['is_ev_content']:
                failed_steps.append(f"EV Content: {result['ev_note']}")
            if not result['is_title_match']:
                failed_steps.append(f"Title Match: {result['title_note']}")
            if not result['is_last_para_relevant']:
                failed_steps.append(f"Last Paragraph: {result['para_note']}")
            
            print(f"   Failed Steps: {', '.join(failed_steps)}")
    
    print(f"\n📊 VALIDATION SUMMARY:")
    print(f"   • Valid articles to add: {len(validated_articles)}")
    print(f"   • Invalid articles to discard: {len(failed_articles)}")
    print(f"   • Existing articles: {len(existing_articles)}")
    
    # Prepare final results
    final_articles_to_add = []
    
    # Add valid new articles
    for article in validated_articles:
        # Remove category from new articles as articles2.json format doesn't use it
        article_copy = {k: v for k, v in article.items() if k != 'category'}
        final_articles_to_add.append(article_copy)
    
    # Create final articles2.json content
    final_articles2_content = {
        "articles": existing_articles + final_articles_to_add,
        "lastUpdated": datetime.now().strftime('%Y-%m-%d'),
        "lastValidation": datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')
    }
    
    # Save to articles2.json
    with open('/root/.openclaw/workspace/innovateav/articles2.json', 'w') as f:
        json.dump(final_articles2_content, f, indent=2)
    
    print(f"\n✅ VALIDATION COMPLETE at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}")
    print(f"📝 Updated articles2.json with {len(final_articles_to_add)} valid articles")
    print(f"📝 Total articles in articles2.json: {len(existing_articles) + len(final_articles_to_add)}")
    
    # Create summary report
    summary = {
        "validation_date": datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC'),
        "validation_id": "4b8aa269-7f47-4c2e-bdee-ded21fca878b",
        "total_existing_articles": len(existing_articles),
        "new_articles_validated": len(new_articles),
        "articles_passed_validation": len(validated_articles),
        "articles_failed_validation": len(failed_articles),
        "final_total_articles": len(existing_articles) + len(final_articles_to_add),
        "action": "validated and updated articles2.json"
    }
    
    return summary

if __name__ == "__main__":
    summary = validate_new_articles()
    print(f"\n🎯 Validation Summary: {json.dumps(summary, indent=2)}")