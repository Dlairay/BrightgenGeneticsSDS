from typing import Dict, List, Callable, Any, Optional
from google.adk.agents import Agent
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.genai import types
import logging
import json

# Suppress logging noise
logging.basicConfig(level=logging.ERROR)

# Suppress Google ADK verbose logs
logging.getLogger('google_adk').setLevel(logging.ERROR)
logging.getLogger('google.adk').setLevel(logging.ERROR)
logging.getLogger('google_genai').setLevel(logging.ERROR)
logging.getLogger('google.genai').setLevel(logging.ERROR)


class ChatbotAgent:
    """
    A reusable chatbot module built on Google Agent Development Kit.
    Adapted for the SDS backend architecture.
    """
    
    def __init__(self, app_name: str, model: str = "gemini-2.0-flash"):
        self.app_name = app_name
        self.model = model
        self.agents: Dict[str, Agent] = {}
        self.session_service = InMemorySessionService()
        self.runners: Dict[str, Runner] = {}
        
    def add_tool(self, func: Callable) -> Callable:
        """Decorator to register a tool function."""
        return func
    
    def create_agent(
        self,
        name: str,
        description: str,
        instruction: str,
        tools: List[Callable],
        agent_id: Optional[str] = None
    ) -> str:
        """
        Create and register a new agent.
        
        Args:
            name: Agent name
            description: Agent description
            instruction: System instruction for the agent
            tools: List of tool functions
            agent_id: Optional custom agent ID (defaults to name)
            
        Returns:
            Agent ID for referencing the agent
        """
        agent_id = agent_id or name
        
        agent = Agent(
            name=name,
            model=self.model,
            description=description,
            instruction=instruction,
            tools=tools,
        )
        
        self.agents[agent_id] = agent
        
        runner = Runner(
            agent=agent,
            app_name=self.app_name,
            session_service=self.session_service
        )
        
        self.runners[agent_id] = runner
        
        print(f"Agent '{name}' created with ID '{agent_id}'")
        return agent_id
    
    async def create_session(self, user_id: str, session_id: str) -> dict:
        """Create a new session for a user."""
        session = await self.session_service.create_session(
            app_name=self.app_name,
            user_id=user_id,
            session_id=session_id
        )
        
        return {
            "app_name": self.app_name,
            "user_id": user_id,
            "session_id": session_id,
            "session": session
        }
    
    async def chat(
        self,
        agent_id: str,
        query: str,
        user_id: str,
        session_id: str,
        context: Optional[Dict[str, Any]] = None,
        verbose: bool = False
    ) -> str:
        """
        Send a message to an agent and get response.
        
        Args:
            agent_id: ID of the agent to use
            query: User's message
            user_id: User identifier
            session_id: Session identifier
            context: Optional context data (e.g., child profile, traits)
            verbose: Whether to print debug info
            
        Returns:
            Agent's response text
        """
        if agent_id not in self.runners:
            raise ValueError(f"Agent '{agent_id}' not found. Available agents: {list(self.agents.keys())}")
        
        runner = self.runners[agent_id]
        
        if verbose:
            print(f"\n>>> User Query to '{agent_id}': {query}")
        
        # If context is provided, we can enhance the query with context
        if context:
            enhanced_query = f"{query}\n\nContext: {json.dumps(context, indent=2)}"
        else:
            enhanced_query = query
        
        content = types.Content(role='user', parts=[types.Part(text=enhanced_query)])
        final_response = "I'm having trouble processing your request. Please try again."
        
        try:
            async for event in runner.run_async(
                user_id=user_id,
                session_id=session_id,
                new_message=content
            ):
                if event.is_final_response():
                    if event.content and event.content.parts:
                        final_response = event.content.parts[0].text
                    elif getattr(event, 'actions', None) and event.actions.escalate:
                        final_response = f"I need assistance with this request: {event.error_message or 'Complex query requiring human support.'}"
                    break
        except Exception as e:
            final_response = f"I apologize, but I encountered an error: {str(e)}"
        
        if verbose:
            print(f"<<< Agent Response: {final_response}")
        
        return final_response
    
    def list_agents(self) -> List[str]:
        """Get list of available agent IDs."""
        return list(self.agents.keys())
    
    def get_agent_info(self, agent_id: str) -> Dict[str, Any]:
        """Get information about a specific agent."""
        if agent_id not in self.agents:
            raise ValueError(f"Agent '{agent_id}' not found")
        
        agent = self.agents[agent_id]
        return {
            "name": agent.name,
            "model": agent.model,
            "description": agent.description,
            "instruction": agent.instruction,
            "tools": [tool.__name__ for tool in agent.tools] if agent.tools else []
        }


class ChildCareChatbot(ChatbotAgent):
    """Specialized chatbot for child care and genetic profiling assistance."""
    
    def __init__(self, app_name: str = "childcare_assistant"):
        super().__init__(app_name)
        self._tools_setup = False
        self._agents_created = False
    
    def _ensure_initialized(self):
        """Ensure tools and agents are created (lazy initialization)."""
        if not self._tools_setup:
            self._setup_tools()
            self._tools_setup = True
        
        if not self._agents_created:
            self._create_agents()
            self._agents_created = True
    
    def _setup_tools(self):
        """Setup child care related tools."""
        
        @self.add_tool
        def get_trait_information(trait_name: str) -> dict:
            """Get information about a specific genetic trait."""
            print(f"--- Tool: get_trait_information called for trait: {trait_name} ---")
            
            # This would be replaced with actual database lookup in service layer
            trait_info = {
                "adhd": {
                    "name": "ADHD (Attention Deficit Hyperactivity Disorder)",
                    "description": "A neurodevelopmental disorder characterized by inattention, hyperactivity, and impulsivity.",
                    "recommendations": [
                        "Structured daily routines can help",
                        "Break tasks into smaller, manageable parts",
                        "Use visual schedules and reminders",
                        "Provide regular physical activity breaks"
                    ]
                },
                "autism": {
                    "name": "Autism Spectrum Disorder",
                    "description": "A developmental disorder affecting communication and behavior.",
                    "recommendations": [
                        "Use clear, concrete language",
                        "Maintain consistent routines",
                        "Provide sensory-friendly environments",
                        "Use visual supports for communication"
                    ]
                },
                "allergies": {
                    "name": "Allergies",
                    "description": "Immune system reactions to certain substances.",
                    "recommendations": [
                        "Keep detailed allergy records",
                        "Read food labels carefully",
                        "Have emergency medications available",
                        "Inform all caregivers about allergies"
                    ]
                }
            }
            
            trait_normalized = trait_name.lower()
            if trait_normalized in trait_info:
                return {
                    "status": "success",
                    "trait": trait_info[trait_normalized]
                }
            else:
                return {
                    "status": "not_found",
                    "message": f"Information about '{trait_name}' is not available."
                }
        
        @self.add_tool
        def get_development_milestones(age_months: int) -> dict:
            """Get developmental milestones for a specific age."""
            print(f"--- Tool: get_development_milestones called for age: {age_months} months ---")
            
            milestones = {
                6: {
                    "physical": ["Sits without support", "Rolls over in both directions"],
                    "cognitive": ["Shows curiosity about things", "Responds to own name"],
                    "social": ["Knows familiar faces", "Likes to play with others"]
                },
                12: {
                    "physical": ["Stands alone", "May take first steps"],
                    "cognitive": ["Explores objects in different ways", "Finds hidden objects"],
                    "social": ["Shows fear of strangers", "Has favorite toys"]
                },
                24: {
                    "physical": ["Runs and kicks ball", "Walks up and down stairs"],
                    "cognitive": ["Sorts shapes and colors", "Follows two-step instructions"],
                    "social": ["Copies others", "Shows independence"]
                }
            }
            
            # Find closest age milestone
            available_ages = list(milestones.keys())
            closest_age = min(available_ages, key=lambda x: abs(x - age_months))
            
            return {
                "status": "success",
                "age_months": closest_age,
                "milestones": milestones[closest_age]
            }
        
        @self.add_tool
        def suggest_activities(child_age_months: int, traits: Optional[List[str]] = None) -> dict:
            """Suggest age-appropriate activities considering child's traits."""
            print(f"--- Tool: suggest_activities for age: {child_age_months} months, traits: {traits} ---")
            
            base_activities = {
                "0-6": ["Tummy time", "Reading books", "Singing songs", "Sensory play"],
                "6-12": ["Peek-a-boo", "Stacking blocks", "Music and movement", "Water play"],
                "12-24": ["Art activities", "Simple puzzles", "Outdoor exploration", "Pretend play"],
                "24+": ["Building with blocks", "Role playing", "Nature walks", "Simple board games"]
            }
            
            # Determine age group
            if child_age_months < 6:
                age_group = "0-6"
            elif child_age_months < 12:
                age_group = "6-12"
            elif child_age_months < 24:
                age_group = "12-24"
            else:
                age_group = "24+"
            
            activities = base_activities[age_group]
            
            # Add trait-specific activities if provided
            if traits and "adhd" in [t.lower() for t in traits]:
                activities.extend(["Physical exercise", "Short focused tasks", "Movement breaks"])
            
            return {
                "status": "success",
                "age_group": age_group,
                "activities": activities
            }
        
        self.get_trait_information = get_trait_information
        self.get_development_milestones = get_development_milestones
        self.suggest_activities = suggest_activities
    
    def _create_agents(self):
        """Create specialized child care agents."""
        
        # General parenting assistant
        self.create_agent(
            name="parenting_assistant",
            description="Provides general parenting advice and support",
            instruction=(
                "You are a supportive and knowledgeable parenting assistant. "
                "Provide evidence-based advice while being empathetic and understanding. "
                "Always prioritize child safety and well-being. "
                "If asked about medical concerns, advise consulting healthcare professionals. "
                "Be encouraging and positive while offering practical solutions."
            ),
            tools=[self.get_development_milestones, self.suggest_activities],
            agent_id="general"
        )
        
        # Genetic traits specialist
        self.create_agent(
            name="genetic_traits_specialist",
            description="Helps understand and manage genetic traits",
            instruction=(
                "You are a specialist in genetic traits and their impact on child development. "
                "Use the get_trait_information tool to provide accurate information. "
                "Focus on practical management strategies and positive approaches. "
                "Emphasize that genetic predispositions are just one factor in development. "
                "Always maintain a supportive and non-judgmental tone."
            ),
            tools=[self.get_trait_information],
            agent_id="traits"
        )
        
        # Child development expert
        self.create_agent(
            name="development_expert",
            description="Expert in child development milestones and activities",
            instruction=(
                "You are an expert in child development and age-appropriate activities. "
                "Use the tools to provide accurate milestone information and activity suggestions. "
                "Consider individual differences and genetic traits when making recommendations. "
                "Encourage parents while being realistic about developmental variations. "
                "Suggest when professional evaluation might be beneficial."
            ),
            tools=[self.get_development_milestones, self.suggest_activities, self.get_trait_information],
            agent_id="development"
        )
        
        # Dr. Bloom - Medical concern specialist
        self.create_agent(
            name="dr_bloom",
            description="Medical concern specialist for child health issues",
            instruction=(
                "You are Dr. Bloom. Keep responses SHORT and ACTIONABLE.\n\n"
                "FORMAT:\n"
                "1. One sentence acknowledgment\n"
                "2. Bullet points of 2-3 specific actions\n"
                "3. Skip explanations unless asked\n\n"
                "EXAMPLE:\n"
                "Parent: 'My child is having a meltdown over not getting a toy'\n"
                "You: 'Tantrums over disappointment are tough. Try these:\n"
                "• Say \"I see you're upset about the toy\"\n"
                "• Offer 2 choices: \"blocks or story time?\"\n"
                "• If escalating, give space until calm'\n\n"
                "NO ESSAYS. Just diagnosis + actionable steps."
            ),
            tools=[self.get_trait_information, self.suggest_activities],
            agent_id="dr_bloom"
        )
        
    
    async def chat(self, agent_id: str, query: str, user_id: str, session_id: str, 
                   context: Optional[Dict[str, Any]] = None, verbose: bool = False) -> str:
        """Override parent chat method to ensure initialization."""
        self._ensure_initialized()
        return await super().chat(agent_id, query, user_id, session_id, context, verbose)
    
    def list_agents(self) -> List[str]:
        """Override to ensure initialization."""
        self._ensure_initialized()
        return super().list_agents()
    
    def get_agent_info(self, agent_id: str) -> Dict[str, Any]:
        """Override to ensure initialization."""
        self._ensure_initialized()
        return super().get_agent_info(agent_id)