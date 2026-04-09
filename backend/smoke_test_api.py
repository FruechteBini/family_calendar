import json
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import date, datetime, timedelta


BASE_URL = "http://127.0.0.1:8000"


def _json_request(method: str, path: str, token: str | None = None, data: dict | None = None, query: dict | None = None):
    url = f"{BASE_URL}{path}"
    if query:
        url = f"{url}?{urllib.parse.urlencode(query)}"

    body = None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if data is not None:
        body = json.dumps(data).encode("utf-8")

    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
            if not raw:
                return resp.status, None
            return resp.status, json.loads(raw.decode("utf-8"))
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            payload = json.loads(raw.decode("utf-8")) if raw else None
        except Exception:
            payload = raw.decode("utf-8", errors="replace") if raw else None
        return e.code, payload


def _iso(d: date) -> str:
    return d.isoformat()


def _monday_of(d: date) -> date:
    return d - timedelta(days=d.weekday())


def assert_ok(name: str, status: int, payload):
    if status < 200 or status >= 300:
        raise RuntimeError(f"{name} failed: status={status}, payload={payload}")


def main():
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    username = f"test_{ts}"
    password = f"TestPass!_{ts}"

    print(f"[1] Register user: {username}")
    st, p = _json_request("POST", "/api/auth/register", data={"username": username, "password": password})
    assert_ok("register", st, p)

    print("[2] Login")
    st, p = _json_request("POST", "/api/auth/login", data={"username": username, "password": password})
    assert_ok("login", st, p)
    token = p["access_token"]

    print("[3] Create family")
    st, p = _json_request("POST", "/api/auth/family", token=token, data={"name": f"TestFamily_{ts}"})
    assert_ok("create_family", st, p)
    family_id = p["id"]

    print("[4] Create member")
    st, p = _json_request("POST", "/api/family-members/", token=token, data={"name": "Tester", "emoji": "🧪", "color": "#00C2A8"})
    assert_ok("create_member", st, p)
    member_id = p["id"]

    print("[5] Create category")
    st, p = _json_request("POST", "/api/categories/", token=token, data={"name": f"TestCat_{ts}", "color": "#3B82F6"})
    assert_ok("create_category", st, p)
    category_id = p["id"]

    print("[6] Create recipe")
    recipe_payload = {
        "title": f"TestRecipe_{ts}",
        "notes": "Smoke test recipe",
        "difficulty": "medium",
        "prep_time_active_minutes": 15,
        "image_url": None,
        "ingredients": [{"name": "Nudeln", "amount": 200, "unit": "g"}],
    }
    st, p = _json_request("POST", "/api/recipes/", token=token, data=recipe_payload)
    assert_ok("create_recipe", st, p)
    recipe_id = p["id"]

    today = date.today()
    monday = _monday_of(today)
    today_str = _iso(today)
    monday_str = _iso(monday)

    print("[7] Meals: GET week plan")
    st, p = _json_request("GET", "/api/meals/plan", token=token, query={"week": monday_str})
    assert_ok("get_week_plan", st, p)

    print("[8] Meals: set dinner slot for today")
    st, p = _json_request(
        "PUT",
        f"/api/meals/plan/{today_str}/dinner",
        token=token,
        data={"recipe_id": recipe_id, "servings_planned": 2},
    )
    assert_ok("set_meal_slot", st, p)

    print("[9] Meals: mark cooked")
    st, p = _json_request("PATCH", f"/api/meals/plan/{today_str}/dinner/done", token=token, data={"servings_cooked": 2})
    assert_ok("mark_cooked", st, p)

    print("[10] Shopping: generate list for week")
    st, p = _json_request("POST", "/api/shopping/generate", token=token, data={"week_start": monday_str})
    assert_ok("shopping_generate", st, p)
    shopping_list_id = p["id"]

    print("[11] Shopping: add manual item")
    st, p = _json_request("POST", "/api/shopping/items", token=token, data={"name": "Kaffee", "amount": "1", "unit": "Pck", "category": "sonstiges"})
    assert_ok("shopping_add_item", st, p)
    item_id = p["id"]

    print("[12] Shopping: toggle check")
    st, p = _json_request("PATCH", f"/api/shopping/items/{item_id}/check", token=token)
    assert_ok("shopping_check_toggle", st, p)

    print("[13] Shopping: sort (AI)")
    st, p = _json_request("POST", "/api/shopping/sort", token=token)
    # Can fail if ANTHROPIC key invalid; report but don't abort whole run
    if st < 200 or st >= 300:
        print(f"  - WARN: shopping sort not ok (status={st}) payload={p}")
    else:
        print("  - OK")

    print("[14] Pantry: add item")
    st, p = _json_request("POST", "/api/pantry/", token=token, data={"name": "Milch", "quantity": 1.0, "unit": "L", "category": "kuehlregal"})
    assert_ok("pantry_add", st, p)
    pantry_id = p["id"]

    print("[15] Pantry: get alerts")
    st, p = _json_request("GET", "/api/pantry/alerts", token=token)
    assert_ok("pantry_alerts", st, p)

    print("[16] Events: create + list")
    start = datetime.now().replace(microsecond=0)
    end = start + timedelta(hours=1)
    st, p = _json_request(
        "POST",
        "/api/events/",
        token=token,
        data={
            "title": "SmokeTest Event",
            "description": "created by smoke test",
            "start": start.isoformat(),
            "end": end.isoformat(),
            "all_day": False,
            "category_id": category_id,
            "member_ids": [member_id],
        },
    )
    assert_ok("event_create", st, p)
    st, p = _json_request("GET", "/api/events/", token=token, query={"date_from": start.isoformat(), "date_to": end.isoformat()})
    assert_ok("event_list", st, p)

    print("[17] Todos: create + complete")
    st, p = _json_request(
        "POST",
        "/api/todos/",
        token=token,
        data={
            "title": "SmokeTest Todo",
            "description": "todo created by smoke test",
            "priority": "medium",
            "completed": False,
            "category_id": category_id,
            "member_ids": [member_id],
        },
    )
    assert_ok("todo_create", st, p)
    todo_id = p["id"]
    st, p = _json_request("PATCH", f"/api/todos/{todo_id}/complete", token=token, data={"completed": True})
    assert_ok("todo_complete", st, p)

    print("[18] AI: available-recipes + generate preview + confirm + undo (lightweight)")
    st, p = _json_request("GET", "/api/ai/available-recipes", token=token, query={"week_start": monday_str})
    if st < 200 or st >= 300:
        print(f"  - WARN: ai available-recipes not ok (status={st})")
    else:
        # Pick first empty slot for preview generation if present, else skip
        empty_slots = p.get("empty_slots") or []
        if empty_slots:
            slot = empty_slots[0]
            gen_req = {
                "week_start": monday_str,
                "servings": 2,
                "preferences": "Smoke test",
                "selected_slots": [{"date": slot["date"], "slot": slot["slot"]}],
                "include_cookidoo": False,
            }
            st2, p2 = _json_request("POST", "/api/ai/generate-meal-plan", token=token, data=gen_req)
            if 200 <= st2 < 300 and p2 and p2.get("suggestions"):
                # Confirm and undo so DB stays clean-ish
                conf_req = {"week_start": monday_str, "items": p2["suggestions"]}
                st3, p3 = _json_request("POST", "/api/ai/confirm-meal-plan", token=token, data=conf_req)
                if 200 <= st3 < 300:
                    meal_ids = p3.get("meal_ids") or []
                    if meal_ids:
                        _json_request("POST", "/api/ai/undo-meal-plan", token=token, data={"meal_ids": meal_ids})
                print("  - OK")
            else:
                print(f"  - WARN: ai generate-meal-plan not ok (status={st2}) payload={p2}")
        else:
            print("  - SKIP: no empty slots for AI preview")

    print("[19] Clean up: clear meal slot + shopping list clear-all")
    _json_request("DELETE", f"/api/meals/plan/{today_str}/dinner", token=token)
    _json_request("POST", "/api/shopping/clear-all", token=token)
    _json_request("DELETE", f"/api/pantry/{pantry_id}", token=token)

    print("[20] Integrations: Cookidoo status + Knuspr delivery slots/search (non-destructive)")
    st, p = _json_request("GET", "/api/cookidoo/status", token=token)
    if st < 200 or st >= 300:
        print(f"  - WARN: cookidoo status not ok (status={st})")
    else:
        print("  - OK cookidoo status")
    st, p = _json_request("GET", "/api/knuspr/delivery-slots", token=token)
    if st < 200 or st >= 300:
        print(f"  - WARN: knuspr delivery-slots not ok (status={st})")
    else:
        print("  - OK knuspr delivery-slots")
    st, p = _json_request("GET", "/api/knuspr/products/search", token=token, query={"q": "milch"})
    if st < 200 or st >= 300:
        print(f"  - WARN: knuspr search not ok (status={st})")
    else:
        print("  - OK knuspr search")

    print("\nSMOKE TEST OK")
    print(f"User={username} family_id={family_id} shopping_list_id={shopping_list_id} recipe_id={recipe_id}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"\nSMOKE TEST FAILED: {e}")
        sys.exit(1)

