"""Document preprocessing utilities for knowledge base."""

import re
import logging
from typing import List, Dict, Any, Optional
from langchain.schema import Document

logger = logging.getLogger(__name__)


class DocumentPreprocessor:
    """Preprocesses documents before embedding to improve RAG quality."""
    
    def __init__(self):
        """Initialize document preprocessor."""
        pass
    
    def clean_text(self, text: str) -> str:
        """Clean and normalize text content.
        
        Args:
            text: Raw text to clean
            
        Returns:
            Cleaned text
        """
        if not text:
            return ""
        
        # Remove excessive whitespace
        text = re.sub(r'\s+', ' ', text)
        
        # Remove page numbers and headers/footers patterns
        text = re.sub(r'\b(Page|PAGE)\s+\d+\b', '', text)
        text = re.sub(r'\b\d+\s+of\s+\d+\b', '', text)
        
        # Remove figure/table references that don't add value
        text = re.sub(r'\(Figure\s+\d+\)', '', text)
        text = re.sub(r'\(Table\s+\d+\)', '', text)
        text = re.sub(r'Figure\s+\d+:', 'Figure:', text)
        text = re.sub(r'Table\s+\d+:', 'Table:', text)
        
        # Clean up common PDF artifacts
        text = re.sub(r'[^\w\s\.,!?;:()\-\'\"/%]', ' ', text)
        
        # Remove URLs (often not useful in developmental research)
        text = re.sub(r'http[s]?://\S+', '', text)
        text = re.sub(r'www\.\S+', '', text)
        
        # Normalize punctuation spacing
        text = re.sub(r'\s+([,.!?;:])', r'\1', text)
        text = re.sub(r'([,.!?;:])\s+', r'\1 ', text)
        
        # Remove extra spaces and normalize
        text = re.sub(r'\s+', ' ', text).strip()
        
        return text
    
    def extract_key_phrases(self, text: str) -> List[str]:
        """Extract key developmental phrases from text.
        
        Args:
            text: Text to analyze
            
        Returns:
            List of key phrases
        """
        # Developmental keywords and phrases
        developmental_patterns = [
            r'\b\d+-\d+\s+(?:year|month|week)s?\s+old\b',  # Age ranges
            r'\bcognitive\s+development\b',
            r'\bmotor\s+skills?\b',
            r'\bsocial\s+development\b',
            r'\blanguage\s+development\b',
            r'\bemotional\s+regulation\b',
            r'\bexecutive\s+function\b',
            r'\bworking\s+memory\b',
            r'\battention\s+span\b',
            r'\bfine\s+motor\b',
            r'\bgross\s+motor\b',
            r'\bdevelopmental\s+milestone\b',
            r'\bearly\s+childhood\b',
            r'\btoddler\s+development\b',
            r'\bpreschool\s+activities\b',
            # Medical/immunity patterns
            r'\bimmune\s+system\b',
            r'\ballergic\s+reaction\b',
            r'\bfever\b',
            r'\binfection\b',
            r'\bsymptoms?\b',
            r'\bmedical\s+emergency\b',
            r'\bpediatric\b',
            r'\bchildhood\s+illness\b',
            r'\bvaccination\b',
            r'\bresilienc\b',
            r'\bstress\s+response\b'
        ]
        
        key_phrases = []
        text_lower = text.lower()
        
        for pattern in developmental_patterns:
            matches = re.finditer(pattern, text_lower)
            for match in matches:
                phrase = match.group().strip()
                if phrase not in key_phrases:
                    key_phrases.append(phrase)
        
        return key_phrases
    
    def enhance_metadata(self, document: Document) -> Document:
        """Enhance document metadata with extracted information.
        
        Args:
            document: Document to enhance
            
        Returns:
            Enhanced document
        """
        text = document.page_content
        metadata = document.metadata.copy()
        
        # Extract key phrases (join as string for ChromaDB compatibility)
        key_phrases = self.extract_key_phrases(text)
        if key_phrases:
            metadata['key_phrases'] = ', '.join(key_phrases)
        
        # Detect age ranges mentioned (join as string for ChromaDB compatibility)
        age_ranges = self._extract_age_ranges(text)
        if age_ranges:
            metadata['age_ranges'] = ', '.join(age_ranges)
        
        # Classify content type
        content_type = self._classify_content_type(text)
        metadata['content_type'] = content_type
        
        # Estimate content quality/relevance
        relevance_score = self._estimate_relevance(text)
        metadata['relevance_score'] = relevance_score
        
        # Update document
        enhanced_doc = Document(
            page_content=self.clean_text(text),
            metadata=metadata
        )
        
        return enhanced_doc
    
    def _extract_age_ranges(self, text: str) -> List[str]:
        """Extract age ranges from text.
        
        Args:
            text: Text to analyze
            
        Returns:
            List of age ranges found
        """
        age_patterns = [
            r'\b(\d+)-(\d+)\s+(?:year|month|week)s?\s+old\b',
            r'\b(\d+)\s+to\s+(\d+)\s+(?:year|month|week)s?\b',
            r'\bearly\s+childhood\b',
            r'\btoddler\b',
            r'\bpreschool\b',
            r'\binfant\b',
            r'\bnewborn\b'
        ]
        
        age_ranges = []
        text_lower = text.lower()
        
        for pattern in age_patterns:
            matches = re.finditer(pattern, text_lower)
            for match in matches:
                age_range = match.group().strip()
                if age_range not in age_ranges:
                    age_ranges.append(age_range)
        
        return age_ranges
    
    def _classify_content_type(self, text: str) -> str:
        """Classify the type of content.
        
        Args:
            text: Text to classify
            
        Returns:
            Content type classification
        """
        text_lower = text.lower()
        
        # Research paper indicators
        research_indicators = ['study', 'research', 'participants', 'methodology', 'results', 'conclusion']
        research_score = sum(1 for indicator in research_indicators if indicator in text_lower)
        
        # Activity guide indicators
        activity_indicators = ['activity', 'game', 'play', 'exercise', 'practice', 'instructions']
        activity_score = sum(1 for indicator in activity_indicators if indicator in text_lower)
        
        # Guidelines indicators
        guideline_indicators = ['guideline', 'recommendation', 'should', 'important', 'key points']
        guideline_score = sum(1 for indicator in guideline_indicators if indicator in text_lower)
        
        # Determine primary type
        scores = {
            'research': research_score,
            'activity': activity_score,
            'guideline': guideline_score
        }
        
        primary_type = max(scores, key=scores.get)
        
        if scores[primary_type] == 0:
            return 'general'
        
        return primary_type
    
    def _estimate_relevance(self, text: str) -> float:
        """Estimate relevance score for developmental recommendations.
        
        Args:
            text: Text to analyze
            
        Returns:
            Relevance score between 0 and 1
        """
        text_lower = text.lower()
        
        # High-value keywords
        high_value_keywords = [
            'development', 'cognitive', 'motor', 'social', 'emotional',
            'language', 'learning', 'skills', 'milestone', 'activity',
            'intervention', 'strategy', 'evidence', 'research'
        ]
        
        # Medium-value keywords
        medium_value_keywords = [
            'child', 'children', 'toddler', 'preschool', 'early',
            'play', 'game', 'exercise', 'practice', 'education'
        ]
        
        # Calculate relevance score
        high_score = sum(2 for keyword in high_value_keywords if keyword in text_lower)
        medium_score = sum(1 for keyword in medium_value_keywords if keyword in text_lower)
        
        total_score = high_score + medium_score
        text_length = len(text.split())
        
        # Normalize by text length (longer texts should have higher scores)
        if text_length > 0:
            relevance = min(1.0, total_score / max(10, text_length * 0.1))
        else:
            relevance = 0.0
        
        return relevance
    
    def filter_low_quality_chunks(
        self,
        documents: List[Document],
        min_length: int = 50,
        min_relevance: float = 0.1
    ) -> List[Document]:
        """Filter out low-quality document chunks.
        
        Args:
            documents: List of documents to filter
            min_length: Minimum character length
            min_relevance: Minimum relevance score
            
        Returns:
            Filtered list of documents
        """
        filtered_docs = []
        
        for doc in documents:
            # Check length
            if len(doc.page_content) < min_length:
                continue
            
            # Check relevance if available
            relevance = doc.metadata.get('relevance_score', 1.0)
            if relevance < min_relevance:
                continue
            
            # Check for mostly non-alphabetic content
            alpha_ratio = len(re.findall(r'[a-zA-Z]', doc.page_content)) / len(doc.page_content)
            if alpha_ratio < 0.5:
                continue
            
            filtered_docs.append(doc)
        
        logger.info(f"Filtered {len(documents)} documents to {len(filtered_docs)} high-quality chunks")
        return filtered_docs
    
    def preprocess_documents(self, documents: List[Document]) -> List[Document]:
        """Preprocess a list of documents.
        
        Args:
            documents: Documents to preprocess
            
        Returns:
            Preprocessed documents
        """
        if not documents:
            return []
        
        processed_docs = []
        
        for doc in documents:
            try:
                # Enhance metadata and clean text
                enhanced_doc = self.enhance_metadata(doc)
                processed_docs.append(enhanced_doc)
            except Exception as e:
                logger.warning(f"Failed to preprocess document: {e}")
                # Keep original if preprocessing fails
                processed_docs.append(doc)
        
        # Filter low-quality chunks
        filtered_docs = self.filter_low_quality_chunks(processed_docs)
        
        logger.info(f"Preprocessed {len(documents)} documents into {len(filtered_docs)} high-quality chunks")
        return filtered_docs