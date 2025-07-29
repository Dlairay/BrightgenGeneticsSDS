"""
Shared utility functions used across the application.
"""
import base64
from typing import Optional, Tuple


def encode_image_to_base64(image_bytes: bytes) -> str:
    """
    Encode image bytes to base64 string.
    
    Args:
        image_bytes: Raw image bytes
        
    Returns:
        Base64 encoded string
    """
    return base64.b64encode(image_bytes).decode('utf-8')


def decode_base64_to_bytes(base64_string: str) -> bytes:
    """
    Decode base64 string to bytes.
    
    Args:
        base64_string: Base64 encoded string
        
    Returns:
        Decoded bytes
    """
    return base64.b64decode(base64_string)


def prepare_image_for_llm(image_base64: str, image_type: Optional[str] = None) -> Tuple[bytes, str]:
    """
    Prepare a base64 image for sending to an LLM.
    
    Args:
        image_base64: Base64 encoded image string
        image_type: MIME type (e.g., 'image/jpeg', 'image/png')
        
    Returns:
        Tuple of (image_bytes, mime_type)
    """
    # Decode the base64 string to bytes
    image_bytes = decode_base64_to_bytes(image_base64)
    
    # Default to JPEG if no type specified
    if not image_type:
        image_type = 'image/jpeg'
    
    return image_bytes, image_type


def validate_image_type(image_type: Optional[str]) -> str:
    """
    Validate and normalize image MIME type.
    
    Args:
        image_type: Input MIME type
        
    Returns:
        Valid MIME type
    """
    valid_types = {
        'image/jpeg': ['image/jpeg', 'jpeg', 'jpg'],
        'image/png': ['image/png', 'png'],
        'image/gif': ['image/gif', 'gif'],
        'image/webp': ['image/webp', 'webp']
    }
    
    if not image_type:
        return 'image/jpeg'
    
    image_type_lower = image_type.lower()
    
    for mime_type, aliases in valid_types.items():
        if image_type_lower in aliases:
            return mime_type
    
    # Default to JPEG for unknown types
    return 'image/jpeg'