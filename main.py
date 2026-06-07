from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import sqlite3
import requests
import datetime
import time 

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Snippet(BaseModel):
    title: str
    code_block: str
    tag: str

def get_db_connection():
    conn = sqlite3.connect("app.db")
    conn.row_factory = sqlite3.Row 
    return conn

@app.get("/")
def home():
    return {"message": "Welcome to the CP Companion API! The server is alive."}

@app.get("/snippets")
def get_all_snippets():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM snippets")
    rows = cursor.fetchall()
    conn.close()
    return {"snippets": rows}

@app.post("/snippets")
def create_snippet(snippet: Snippet):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO snippets (title, code_block, tag) VALUES (?, ?, ?)",
        (snippet.title, snippet.code_block, snippet.tag)
    )
    conn.commit()
    conn.close()
    return {"message": "Snippet saved successfully!"}

@app.get("/contests")
def get_upcoming_contests():
    primary_url = "https://kontests.net/api/v1/all"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0"
    }
    
    try:
        response = requests.get(primary_url, headers=headers, timeout=3)
        if response.status_code == 200:
            all_contests = response.json()
            upcoming = [
                {
                    "name": c.get("name", "Unknown Contest"),
                    "site": c.get("site", "Unknown Platform"),
                    "start_time": c.get("start_time", "Unknown Time")
                }
                for c in all_contests if isinstance(c, dict) and c.get("status") == "BEFORE"
            ]
            upcoming.sort(key=lambda x: x["start_time"])
            return {"contests": upcoming}
        else:
            raise Exception("Primary API returned bad status.")
            
    except Exception as e:
        print(f"Kontests 'All' endpoint failed. Booting up Custom Aggregator...")
        
        custom_upcoming = []
        now = time.time()
        
        # 1. Fetch Codeforces
        try:
            cf_response = requests.get("https://codeforces.com/api/contest.list?gym=false", timeout=4)
            cf_data = cf_response.json()
            if cf_data["status"] == "OK":
                for c in cf_data["result"]:
                    if c["phase"] == "BEFORE":
                        custom_upcoming.append({
                            "name": c["name"],
                            "site": "Codeforces",
                            "start_time": datetime.datetime.fromtimestamp(c["startTimeSeconds"]).strftime('%Y-%m-%d %H:%M')
                        })
        except:
            pass 
            
        # 2. Fetch LeetCode
        try:
            lc_url = "https://leetcode.com/graphql"
            lc_query = {"query": "{ allContests { title startTime } }"}
            lc_response = requests.post(lc_url, json=lc_query, timeout=4)
            lc_data = lc_response.json()
            for c in lc_data["data"]["allContests"]:
                if c["startTime"] > now:
                    custom_upcoming.append({
                        "name": c["title"],
                        "site": "LeetCode",
                        "start_time": datetime.datetime.fromtimestamp(c["startTime"]).strftime('%Y-%m-%d %H:%M')
                    })
        except:
            pass
            
        # 3. Fetch AtCoder
        try:
            ac_response = requests.get("https://kenkoooo.com/atcoder/resources/contests.json", timeout=4)
            if ac_response.status_code == 200:
                for c in ac_response.json():
                    if c["start_epoch_second"] > now:
                        custom_upcoming.append({
                            "name": c["title"],
                            "site": "AtCoder",
                            "start_time": datetime.datetime.fromtimestamp(c["start_epoch_second"]).strftime('%Y-%m-%d %H:%M')
                        })
        except:
            pass

        # 4. Fetch HackerRank
        try:
            hr_response = requests.get("https://www.hackerrank.com/rest/contests/upcoming?limit=10", headers=headers, timeout=4)
            if hr_response.status_code == 200:
                for c in hr_response.json().get("models", []):
                    if c["epoch_starttime"] > now:
                        custom_upcoming.append({
                            "name": c["name"],
                            "site": "HackerRank",
                            "start_time": datetime.datetime.fromtimestamp(c["epoch_starttime"]).strftime('%Y-%m-%d %H:%M')
                        })
        except:
            pass
            
        # 5. Fetch CodeChef
        try:
            cc_response = requests.get("https://kontests.net/api/v1/code_chef", headers=headers, timeout=4)
            if cc_response.status_code == 200:
                for c in cc_response.json():
                    if c.get("status") == "BEFORE":
                        time_string = c.get("start_time", "Unknown Time")[:16] 
                        custom_upcoming.append({
                            "name": c.get("name", "CodeChef Contest"),
                            "site": "CodeChef",
                            "start_time": time_string.replace("T", " ")
                        })
        except:
            pass
            
        custom_upcoming.sort(key=lambda x: x["start_time"])
        
        if len(custom_upcoming) == 0:
            return {"error": "Critical: All contest servers are currently unreachable."}
            
        return {"contests": custom_upcoming}