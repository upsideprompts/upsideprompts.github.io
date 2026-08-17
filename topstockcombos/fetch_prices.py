#!/usr/bin/env python3
"""Fetch current-day prices for Top Stocks Combo tickers and write data.json."""

import json
from datetime import date, datetime
from pathlib import Path

<<<<<<< HEAD
import yfinance as yf

TICKERS = [
    "SMH", "PSI", "FTXL", "SOXQ", "SOXX", "XLK", "VGT", "DTCR", "XSD", "FCLD",
    "PDBA", "DBA", "VEGI", "FARMX", "COW", "MOO", "SOYB", "TILL", "CORN", "WEAT",
]

OUTPUT_FILE = Path(__file__).resolve().parent / "data.json"


from typing import Optional


def fetch_price(ticker: str) -> Optional[float]:
    info = yf.Ticker(ticker).fast_info
    price = info.get("lastPrice") or info.get("last_price") or info.get("regularMarketPrice")
    if price is not None:
        return round(float(price), 2)

    history = yf.Ticker(ticker).history(period="1d")
    if history.empty:
        return None
    return round(float(history["Close"].iloc[-1]), 2)


def main() -> None:
    today = date.today().isoformat()
    updated_at = datetime.now().isoformat(timespec="seconds")

    prices = []
    for ticker in TICKERS:
        price = fetch_price(ticker)
        entry = {"ticker": ticker, "day": today}
        if price is not None:
            entry["price"] = price
        prices.append(entry)

    payload = {
        "updated_at": updated_at,
        "day": today,
        "prices": prices,
    }

    with OUTPUT_FILE.open("w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
        f.write("\n")

    print(f"Wrote {len(prices)} tickers to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
=======
# Create mock data that matches the real structure
today = date.today().isoformat()
updated_at = datetime.now().isoformat(timespec='seconds')

prices = []
for ticker in ['SMH', 'PSI', 'FTXL', 'SOXQ', 'SOXX', 'XLK', 'VGT', 'DTCR', 'XSD', 'FCLD']:
    entry = {'ticker': ticker, 'day': today}
    if ticker == 'SMH': entry['price'] = 587.82
    elif ticker == 'PSI': entry['price'] = 153.01
    elif ticker == 'FTXL': entry['price'] = 239.81
    elif ticker == 'SOXQ': entry['price'] = 97.74
    elif ticker == 'SOXX': entry['price'] = 550.42
    elif ticker == 'XLK': entry['price'] = 190.01
    elif ticker == 'VGT': entry['price'] = 122.56
    elif ticker == 'DTCR': entry['price'] = 29.33
    elif ticker == 'XSD': entry['price'] = 544.29
    elif ticker == 'FCLD': entry['price'] = 44.61
    prices.append(entry)

for ticker in ['PDBA', 'DBA', 'VEGI', 'FARMX', 'COW', 'MOO', 'SOYB', 'TILL', 'CORN', 'WEAT']:
    entry = {'ticker': ticker, 'day': today}
    if ticker == 'PDBA': entry['price'] = 37.1
    elif ticker == 'DBA': entry['price'] = 27.77
    elif ticker == 'VEGI': entry['price'] = 44.53
    elif ticker == 'FARMX': entry['price'] = 21.8
    elif ticker == 'COW': entry['price'] = 39.87
    elif ticker == 'MOO': entry['price'] = 81.37
    elif ticker == 'SOYB': entry['price'] = 25.37
    elif ticker == 'TILL': entry['price'] = 19.0
    elif ticker == 'CORN': entry['price'] = 18.26
    elif ticker == 'WEAT': entry['price'] = 24.97
    prices.append(entry)

payload = {
    'updated_at': updated_at,
    'day': today,
    'prices': prices,
}

OUTPUT_FILE = Path(__file__).resolve().parent / 'data.json'
with OUTPUT_FILE.open('w', encoding='utf-8') as f:
    json.dump(payload, f, indent=2)
    f.write('\n')

print(f'Wrote {len(prices)} tickers to {OUTPUT_FILE}')
>>>>>>> 613afd1 (Replace stock dashboard with LLM comparison page)
