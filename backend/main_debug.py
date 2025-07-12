from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

print("Starting FastAPI app...")
app = FastAPI(title="Child Genetic Profiling API", version="2.0.0")

print("Adding CORS middleware...")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

print("Adding basic auth route...")
try:
    from app.api import auth
    app.include_router(auth.router)
    print("✅ Auth router added successfully")
except Exception as e:
    print(f"❌ Error adding auth router: {e}")
    import traceback
    traceback.print_exc()

print("Adding children route...")
try:
    from app.api import children
    app.include_router(children.router)
    print("✅ Children router added successfully")
except Exception as e:
    print(f"❌ Error adding children router: {e}")
    import traceback
    traceback.print_exc()

print("FastAPI app setup complete!")

if __name__ == "__main__":
    print("Starting uvicorn server...")
    uvicorn.run(app, host="0.0.0.0", port=8001)  # Use different port to avoid conflicts