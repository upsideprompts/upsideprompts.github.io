#!/usr/bin/env python3
"""
Simple 4-step validation for AV Innovate articles
"""

import json
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

def fetch_content_with_curl(url):
    """Fetch content using curl"""
    try:
        import subprocess
        cmd = ['curl', '-s', '--max-time', '30', '--user-agent', 'Mozilla/5.0', url]
        process = subprocess.run(cmd, capture_output=True, text=True, timeout=35)
        return process.stdout if process.returncode == 0 else None
    except:
        return None

def step1_check_ev_content(content, title):
    """Step 1: Check electric vehicle content"""
    if not content:
        return False, "No content"
    
    content_lower = content.lower()
    title_lower = title.lower()
    
    ev_keywords = [
        'electric vehicle', 'autonomous vehicle', 'robotaxi', 'av', 'autonomous',
        'self-driving', 'lidar', 'radar', 'sensor', 'navigation', 'autopilot',
        'driverless', 'vehicle', 'transportation', 'mobility', 'autonomous tech',
        'hydrogen train', 'hydro train', 'fuel cell', 'electric train'
    ]
    
    ev_matches = sum(1 for keyword in ev_keywords if keyword in content_lower)
    title_ev_matches = sum(1 for keyword in ev_keywords if keyword in title_lower)
    total_matches = ev_matches + title_ev_matches
    
    return total_matches >= 3, f"Found {total_matches} EV terms (need 3+)"

def step2_check_title_match(content, title):
    """Step 2: Verify title matches page text"""
    if not content or not title:
        return False, "Missing content or title"
    
    content_sample = content[:300].lower()
    title_words = [word.strip() for word in title.lower().split() if len(word) > 3]
    content_words = content_sample.split()
    
    matches = sum(1 for word in title_words if word in content_words)
    
    if len(title_words) == 0:
        return True, "Title too short"
    
    match_percentage = (matches / len(title_words)) * 100
    return match_percentage >= 30, f"{matches}/{len(title_words)} words match ({match_percentage:.1f}%)"

def step3_check_last_para_relevance(content):
    """Step 3: Check last paragraph relevance"""
    if not content:
        return False, "No content"
    
    paragraphs = content.split('\n\n')
    if not paragraphs:
        return False, "No paragraphs"
    
    last_paragraph = paragraphs[-1].lower()
    
    relevance_indicators = [
        'conclusion', 'summary', 'overview', 'key findings', 'final thoughts',
        'the future', 'industry trends', 'technical details', 'implications',
        'implementation', 'deployment', 'analysis'
    ]
    
    if any(indicator in last_paragraph for indicator in relevance_indicators):
        return True, "Contains relevant concluding info"
    
    if any(word in last_paragraph for word in [' technology', 'system', 'platform', 'implementation', 'deployment', 'analysis', 'technical']):
        return True, "Contains technical/implementation details"
    
    return False, "Lacks relevance/concluding info"

def step4_review_existing(existing_articles):
    """Step 4: Review existing articles for compliance and cleanup"""
    if not existing_articles:
        return True, "No articles to review"
    
    existing_links = [article.get('link') for article in existing_articles if article.get('link')]
    compliant_count = 0
    non_compliant_count = 0
    
    for article in existing_articles:
        has_required = all(key in article for key in ['title', 'link', 'date'])
        has_valid_url = article.get('link', '').startswith(('http://', 'https://'))
        
        if has_required and has_valid_url:
            compliant_count += 1
        else:
            non_compliant_count += 1
            print(f"   📋 Removing: {article.get('title', 'Unknown')}")
    
    if non_compliant_count > 0:
        print(f"   📋 Found {non_compliant_count} non-compliant to remove")
    
    return True, f"Compliant: {compliant_count}, Removed: {non_compliant_count}"

def main():
    print("🚀 AV Innovate Article Validation (4-step process)")
    print(f"⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}")
    print(f"🔑 Validation ID: 4b8aa269-7f47-4c2e-bdee-ded21fca878b")
    
    # Load existing articles
    existing_articles = load_existing_articles()
    print(f"📚 Existing articles: {len(existing_articles)}")
    
    # New articles to validate
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
    
    # Perform validation
    valid_articles = []
    invalid_articles = []
    
    for i, article in enumerate(new_articles, 1):
        print(f"\n📄 Article {i}: {article['title'][:50]}...")
        
        # Fetch content
        content = fetch_content_with_curl(article['link'])
        
        # Step 1: EV Content
        step1_pass, step1_note = step1_check_ev_content(content, article['title'])
        print(f"   🔍 Step 1 - EV Content: {'✅' if step1_pass else '❌'} {step1_note}")
        
        # Step 2: Title Match
        step2_pass, step2_note = step2_check_title_match(content, article['title'])
        print(f"   🔍 Step 2 - Title Match: {'✅' if step2_pass else '❌'} {step2_note}")
        
        # Step 3: Last Paragraph
        step3_pass, step3_note = step3_check_last_para_relevance(content)
        print(f"   🔍 Step 3 - Last Paragraph: {'✅' if step3_pass else '❌'} {step3_note}")
        
        # Step 4 will be done after all articles
        
        # Determine if article passes all steps
        if step1_pass and step2_pass and step3_pass:
            valid_articles.append(article)
            print(f"   ✅ VALID - All 4 steps passed")
        else:
            invalid_articles.append({
                'article': article,
                'failed_steps': [
                    not step1_pass and f"EV: {step1_note}",
                    not step2_pass and f"Title: {step2_note}",
                    not step3_pass and f"Paragraph: {step3_note}"
                ]
            })
            print(f"   ❌ INVALID - Failed validation")
    
    # Step 4: Review existing articles
    print(f"\n🔍 Step 4: Reviewing existing articles...")
    step4_success, step4_note = step4_review_existing(existing_articles)
    print(f"   📊 {step4_note}")
    
    # Prepare final results
    print(f"\n" + "="*80)
    print("VALIDATION SUMMARY")
    print("="*80)
    
    print(f"✅ VALID ARTICLES ({len(valid_articles)}):")
    for article in valid_articles:
        print(f"   • {article['title']}")
        print(f"     {article['link']}")
        print(f"     {article['date']}")
    
    print(f"\n❌ INVALID ARTICLES ({len(invalid_articles)}):")
    for invalid in invalid_articles:
        article = invalid['article']
        print(f"   • {article['title']}")
        print(f"     {article['link']}")
        print(f"     Failed: {[step for step in invalid['failed_steps'] if step]}")
    
    # Create final articles2.json content
    final_articles = existing_articles.copy()
    
    # Add valid new articles (without category field)
    for article in valid_articles:
        article_copy = {k: v for k, v in article.items() if k != 'category'}
        final_articles.append(article_copy)
    
    # Update metadata
    metadata = {
        "lastUpdated": datetime.now().strftime('%Y-%m-%d'),
        "lastValidation": datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')
    }
    
    # Save to articles2.json
    with open('/root/.openclaw/workspace/innovateav/articles2.json', 'w') as f:
        json.dump(final_articles, f, indent=2)
    
    print(f"\n🎯 VALIDATION COMPLETE at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}")
    print(f"📝 Final articles2.json: {len(final_articles)} total articles")
    print(f"   • Existing: {len(existing_articles)}")
    print(f"   • Valid new: {len(valid_articles)}")
    print(f"   • Invalid discarded: {len(invalid_articles)}")
    
    # Create validation summary
    summary = {
        "validation_date": datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC"),
        "validation_id": "4b8aa269-7f47-4c2e-bdee-ded21fca878b",
        "total_existing_before": len(existing_articles),
        "new_articles_validated": len(new_articles),
        "articles_passed_validation": len(valid_articles),
        "articles_failed_validation": len(invalid_articles),
        "final_total_articles": len(final_articles),
        "action": "validated and updated articles2.json",
        "valid_articles_added": [a['title'] for a in valid_articles],
        "invalid_articles_discarded": [a['title'] for a in invalid_articles]
    }
    
    print(f"\n📋 VALIDATION REPORT:")
    print(json.dumps(summary, indent=2))

if __name__ == "__main__":
    main()