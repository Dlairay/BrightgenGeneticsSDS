# CLAUDE.md

## 🧹 Phase 1: Refactor and Restructure My Codebase

I am currently developing a backend for a child development app powered by FastAPI. The backend uses agents to process weekly logs, generate follow-up questions, and provide personalized recommendations based on a genetic profile and historical context.

Please help me refactor the current codebase into a clean and scalable structure. My goals for this refactor are:

1. **Separation of concerns**: Split the logic into clean layers (e.g., agents, API routes, models, services).
2. **Maintainability**: Make it easier to locate logic for agents, logging, child profiles, and recommendations.
3. **Scalability**: Make it ready for deploying on Google Cloud Run (stateless APIs, clean dependencies).
4. **Frontend integration**: `frontend.html` is a prototype to simulate how the FlutterFlow frontend will interact with the backend. Ensure endpoint structure aligns well with a mobile frontend consuming the API.

Please suggest a folder structure like(or something appropriate):

├── agents/
├── api/
├── core/
├── models/
├── services/
├── data/
├── tests/
├── main.py


Also:
- Check if too much logic is in one module (e.g., `childprofile.py`) and suggest ways to extract it.
- Standardize naming and import conventions across files.

---

## 🧩 Phase 2: Add These Features After Refactor

Once the refactor is complete and the app is modular:

### ✅ Feature 1: View Recommendations History
- After user logs in and selects a child, there should be an API endpoint to view recommendation history.
- This endpoint should:
  - Retrieve past logs and extract any generated recommendations.
  - display them in chronological order.
  - Use Firestore as the data source.

### ✅ Feature 2: Unscheduled (Emergency) Check-In
- After selecting a child, the user should be able to trigger a new check-in anytime as another option(besides weekly check in and view recommendation history).
- This feature should:
  - Reuse agent logic to generate prompts or recommendations.
  - Be a new API route like `POST /children/{id}/emergency-checkin`
  - Label logs with `entry_type: emergency` for traceability.

---

## 🌐 Deployment Context

- Final backend will be deployed on **Google Cloud Run**.
- Please help ensure:
  - API is stateless and modular.
  - `requirements.txt` or `pyproject.toml` is lean.
  - Suggestions are compatible with async FastAPI and `firestore`.

---

## ✅ Context

- Working directory: `/Users/ray/Desktop/sds/backend`
- Main entry where fastapi routes are: `main.py`
- Frontend prototype for testing: `frontend.html`
- LLM logic lives in `agent.py` (and related files).
- Log creation is split across `childprofile.py` and agent code.
