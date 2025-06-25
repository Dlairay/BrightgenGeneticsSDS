import vertexai
from vertexai.generative_models import GenerativeModel, Part
import json # Only needed if parsing JSON response or for print formatting
from dotenv import load_dotenv
import os
load_dotenv()

GOOGLE_API_KEY=os.getenv("GOOGLE_API_KEY")  
PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT")  
LOCATION = os.getenv("GOOGLE_CLOUD_LOCATION")         
GOOGLE_GENAI_USE_VERTEXAI = os.getenv("GOOGLE_GENAI_USE_VERTEXAI", "true").lower() == "true"




def generate_fun_fact(model_name="gemini-2.0-flash", prompt_text="Hello, tell me a quick fun fact."):
    try:
        vertexai.init(project=PROJECT_ID, location=LOCATION)
        model = GenerativeModel(model_name)
        response = model.generate_content([Part.from_text(prompt_text)])
        print(response.text)

    except Exception as e:
        print(f"An error occurred: {e}")


