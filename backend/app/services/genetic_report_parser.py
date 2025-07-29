import json
import logging
from google import genai
from app.schemas.child import GeneticReportData
from app.core.utils import encode_image_to_base64, decode_base64_to_bytes

logger = logging.getLogger(__name__)


class GeneticReportParser:
    def __init__(self):
        # Initialize the client for google-genai
        self.client = genai.Client()
        
        # Define the expected output schema in the correct format
        self.output_schema = {
            "type": "object",
            "properties": {
                "child_id": {"type": "string"},
                "birthday": {"type": "string"},
                "gender": {"type": "string"},
                "genotype_profile": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "rs_id": {"type": "string"},
                            "genotype": {"type": "string"}
                        },
                        "required": ["rs_id", "genotype"]
                    }
                }
            },
            "required": ["child_id", "birthday", "gender", "genotype_profile"]
        }
        
    def parse_pdf(self, pdf_content: bytes) -> GeneticReportData:
        """
        Parse a genetic report PDF using Google GenAI (non-async, matching your working example)
        
        Args:
            pdf_content: PDF file content as bytes
            
        Returns:
            GeneticReportData object with extracted information
        """
        try:
            # Convert PDF to base64 first, then decode back to bytes (matching your example)
            pdf_base64 = encode_image_to_base64(pdf_content)
            pdf_bytes = decode_base64_to_bytes(pdf_base64)
            
            # Create the prompt for extraction
            extraction_prompt = """Extract the following information from the provided PDF document and return it as a JSON object.
            The document might contain information about a child's ID, birthday, gender, and a genotype profile
            including rs_id and genotype. If a field is not found, it should still be included in the JSON
            with a null or empty value as appropriate.

            Example Schema:
            {
                "child_id": "child_4",
                "birthday": "2016-06-13",
                "gender": "Male",
                "genotype_profile": [
                    { "rs_id": "rs1021737", "genotype": "TT" },
                    { "rs_id": "rs6283", "genotype": "TT" },
                    { "rs_id": "rs12913832", "genotype": "GG" }
                ]
            }
            """
            
            # Create content using google-genai client API
            contents = [
                genai.types.Content(
                    role="user",
                    parts=[
                        genai.types.Part(text=extraction_prompt),
                        genai.types.Part(
                            inline_data=genai.types.Blob(
                                data=pdf_bytes,  # Use decoded bytes
                                mime_type="application/pdf"
                            )
                        )
                    ]
                )
            ]

            # Define the generation configuration for structured output
            generation_config = genai.types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=self.output_schema,
                temperature=0.1
            )

            # Make the generate content call using the client
            response = self.client.models.generate_content(
                model="gemini-2.0-flash",
                contents=contents,
                config=generation_config
            )

            # The response.text will directly contain the JSON string
            json_text = response.text
            parsed_json = json.loads(json_text)
            
            # Validate and create GeneticReportData
            return GeneticReportData(**parsed_json)
                
        except genai.APIError as e:
            logger.error(f"GenAI API error: {e}")
            raise ValueError(f"GenAI API error: {e}")
        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {e}")
            raise ValueError(f"Failed to parse JSON response from API: {e}")
        except Exception as e:
            logger.error(f"Error parsing genetic report PDF: {str(e)}")
            raise ValueError(f"An unexpected error occurred: {e}")
    
    async def parse_json_or_pdf(self, file_content: bytes, content_type: str) -> GeneticReportData:
        """
        Parse either JSON or PDF genetic report
        
        Args:
            file_content: File content as bytes
            content_type: MIME type of the file
            
        Returns:
            GeneticReportData object
        """
        if content_type == "application/json":
            # Parse as JSON
            try:
                data = json.loads(file_content.decode())
                return GeneticReportData(**data)
            except Exception as e:
                logger.error(f"Failed to parse JSON: {e}")
                raise ValueError("Invalid JSON format")
        elif content_type == "application/pdf":
            # Parse as PDF using GenAI
            return self.parse_pdf(file_content)
        else:
            raise ValueError(f"Unsupported file type: {content_type}")