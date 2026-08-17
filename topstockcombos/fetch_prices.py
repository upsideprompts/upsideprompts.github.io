#!/usr/bin/env python3
"""Fetch current-day prices for Top Stocks Combo tickers and write data.json."""

import json
from datetime import date, datetime
from pathlib import Path

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
