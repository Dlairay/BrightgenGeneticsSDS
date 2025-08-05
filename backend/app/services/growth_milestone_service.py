from typing import List, Dict, Optional, Tuple
from datetime import datetime, date
import math
from app.repositories.growth_milestone_repository import GrowthMilestoneRepository
from app.repositories.child_repository import ChildRepository
from app.models.child_profile import ChildProfile


class GrowthMilestoneService:
    """Service for growth milestone roadmap functionality."""
    
    def __init__(self):
        self.milestone_repo = GrowthMilestoneRepository()
        self.child_repo = ChildRepository()
    
    def _calculate_child_age_years(self, birthday: str) -> int:
        """Calculate child's age in years from birthday string."""
        try:
            if not birthday:
                return 0
            
            # Try multiple date formats
            date_formats = [
                "%Y-%m-%d",           # 2023-03-27
                "%d %B %Y",           # 27 March 2023
                "%d %b %Y",           # 27 Mar 2023
                "%B %d, %Y",          # March 27, 2023
                "%b %d, %Y",          # Mar 27, 2023
                "%m/%d/%Y",           # 03/27/2023
                "%d/%m/%Y",           # 27/03/2023
            ]
            
            birth_date = None
            for date_format in date_formats:
                try:
                    birth_date = datetime.strptime(birthday, date_format).date()
                    break
                except ValueError:
                    continue
            
            if birth_date is None:
                print(f"❌ Could not parse birthday format: {birthday}")
                return 0
            
            today = date.today()
            
            # Calculate age in years
            age = today.year - birth_date.year
            if today.month < birth_date.month or (today.month == birth_date.month and today.day < birth_date.day):
                age -= 1
            
            return max(0, age)
        except Exception as e:
            print(f"❌ Error calculating age from birthday {birthday}: {e}")
            return 0
    
    def _extract_gene_ids_from_traits(self, traits: List[Dict]) -> List[str]:
        """Extract gene IDs from child traits that belong to Growth & Development archetype."""
        growth_genes = []
        
        for trait in traits:
            # Filter for Growth & Development archetype
            if trait.get("archetype", "").lower() == "growth & development":
                gene = trait.get("gene", "")
                if gene and gene not in growth_genes:
                    growth_genes.append(gene)
        
        return growth_genes
    
    async def get_child_roadmap(self, child_id: str) -> Dict:
        """Get the complete growth milestone roadmap for a child with current age highlighting."""
        try:
            # Get PRE-COMPUTED roadmap data (much faster!)
            roadmap_data = await self.child_repo.load_roadmap_data(child_id)
            
            # Fallback: if no pre-computed data, compute on-the-fly (for backwards compatibility)
            if not roadmap_data or not roadmap_data.get('roadmap'):
                print(f"⚠️ No pre-computed roadmap data found for child {child_id}, computing on-the-fly...")
                return await self._compute_roadmap_legacy(child_id)
            
            # Get current child info for age calculation
            report_data = await self.child_repo.load_report(child_id)
            if not report_data:
                raise ValueError(f"Child profile not found: {child_id}")
            
            # Calculate current age from stored birthday or fresh data
            birthday = roadmap_data.get("birthday") or report_data.get("birthday", "")
            current_age = self._calculate_child_age_years(birthday)
            child_name = report_data.get("name", f"Child {child_id}")
            
            # Add age-based highlighting to pre-computed roadmap
            roadmap = self._add_age_highlighting(roadmap_data.get('roadmap', []), current_age)
            
            return {
                "child_id": child_id,
                "child_name": child_name,
                "current_age": current_age,
                "growth_genes": roadmap_data.get('growth_genes', []),
                "roadmap": roadmap
            }
            
        except Exception as e:
            print(f"❌ Error getting child roadmap: {e}")
            raise
    
    async def _build_roadmap(self, gene_ids: List[str], current_age: int) -> List[Dict]:
        """Build the milestone roadmap for given genes."""
        try:
            # Load all milestones for the genes
            all_milestones = []
            for gene_id in gene_ids:
                gene_milestones = await self.milestone_repo.get_milestones_for_gene(gene_id)
                all_milestones.extend(gene_milestones)
            
            if not all_milestones:
                return []
            
            # Group milestones by age ranges
            age_groups = {}
            
            for milestone in all_milestones:
                age_start = milestone.get("age_start", 0)
                age_end = milestone.get("age_end", 0)
                
                # Create age range key
                age_key = f"{age_start}-{age_end}"
                
                if age_key not in age_groups:
                    age_groups[age_key] = {
                        "age_start": age_start,
                        "age_end": age_end,
                        "is_current": age_start <= current_age <= age_end,
                        "is_past": current_age > age_end,
                        "is_future": current_age < age_start,
                        "milestones": []
                    }
                
                # Process food examples
                food_examples = milestone.get("food_examples", "")
                food_list = [food.strip() for food in food_examples.split(",") if food.strip()] if food_examples else []
                
                milestone_data = {
                    "gene_id": milestone.get("gene_id", ""),
                    "trait_name": milestone.get("trait_name", ""),
                    "focus_description": milestone.get("focus_description", ""),
                    "graphic_icon_id": milestone.get("graphic_icon_id", ""),
                    "food_examples": food_list
                }
                
                age_groups[age_key]["milestones"].append(milestone_data)
            
            # Convert to sorted list
            roadmap = []
            for age_key in sorted(age_groups.keys(), key=lambda x: int(x.split("-")[0])):
                age_group = age_groups[age_key]
                
                # Add summary for the age group
                age_group["summary"] = self._create_age_summary(age_group)
                
                roadmap.append(age_group)
            
            return roadmap
            
        except Exception as e:
            print(f"❌ Error building roadmap: {e}")
            return []
    
    def _create_age_summary(self, age_group: Dict) -> str:
        """Create a summary for an age group."""
        age_start = age_group["age_start"]
        age_end = age_group["age_end"]
        milestones = age_group["milestones"]
        
        if not milestones:
            return f"Ages {age_start}-{age_end}: No specific recommendations"
        
        gene_count = len(set(m["gene_id"] for m in milestones))
        trait_names = list(set(m["trait_name"] for m in milestones))
        
        summary = f"Ages {age_start}-{age_end}: "
        
        if gene_count == 1:
            summary += f"Focus on {trait_names[0]}"
        else:
            summary += f"Monitor {gene_count} genetic traits"
        
        if age_group["is_current"]:
            summary += " (Current Age)"
        elif age_group["is_past"]:
            summary += " (Completed)"
        else:
            summary += " (Upcoming)"
        
        return summary
    
    async def get_current_milestones(self, child_id: str) -> Dict:
        """Get only the current age milestones for a child."""
        try:
            # Get child profile
            report_data = await self.child_repo.load_report(child_id)
            if not report_data:
                raise ValueError(f"Child profile not found: {child_id}")
            
            traits = await self.child_repo.load_traits(child_id)
            if not traits:
                raise ValueError(f"Child traits not found: {child_id}")
            
            # Calculate current age
            birthday = report_data.get("birthday", "")
            current_age = self._calculate_child_age_years(birthday)
            
            # Extract Growth & Development genes
            growth_genes = self._extract_gene_ids_from_traits(traits)
            
            if not growth_genes:
                return {
                    "child_id": child_id,
                    "current_age": current_age,
                    "milestones": [],
                    "message": "No Growth & Development traits found"
                }
            
            # Get current milestones
            current_milestones = await self.milestone_repo.get_milestones_for_genes_and_age(
                growth_genes, current_age
            )
            
            # Process milestones
            processed_milestones = []
            for milestone in current_milestones:
                food_examples = milestone.get("food_examples", "")
                food_list = [food.strip() for food in food_examples.split(",") if food.strip()] if food_examples else []
                
                processed_milestones.append({
                    "gene_id": milestone.get("gene_id", ""),
                    "trait_name": milestone.get("trait_name", ""),
                    "focus_description": milestone.get("focus_description", ""),
                    "graphic_icon_id": milestone.get("graphic_icon_id", ""),
                    "food_examples": food_list,
                    "age_start": milestone.get("age_start", 0),
                    "age_end": milestone.get("age_end", 0)
                })
            
            return {
                "child_id": child_id,
                "current_age": current_age,
                "milestones": processed_milestones
            }
            
        except Exception as e:
            print(f"❌ Error getting current milestones: {e}")
            raise
    
    async def get_milestone_overview(self, child_id: str) -> Dict:
        """Get a high-level overview of all milestones for a child."""
        try:
            roadmap_data = await self.get_child_roadmap(child_id)
            
            if not roadmap_data.get("roadmap"):
                return {
                    "child_id": child_id,
                    "overview": roadmap_data.get("message", "No milestones found")
                }
            
            roadmap = roadmap_data["roadmap"]
            current_age = roadmap_data["current_age"]
            
            # Count milestones by status
            past_count = sum(1 for age_group in roadmap if age_group["is_past"])
            current_count = sum(1 for age_group in roadmap if age_group["is_current"])
            future_count = sum(1 for age_group in roadmap if age_group["is_future"])
            
            # Get next milestone
            next_milestone = None
            for age_group in roadmap:
                if age_group["is_future"]:
                    next_milestone = {
                        "age_range": f"{age_group['age_start']}-{age_group['age_end']}",
                        "summary": age_group["summary"],
                        "milestone_count": len(age_group["milestones"])
                    }
                    break
            
            return {
                "child_id": child_id,
                "child_name": roadmap_data["child_name"],
                "current_age": current_age,
                "growth_genes": roadmap_data["growth_genes"],
                "milestone_summary": {
                    "past_milestones": past_count,
                    "current_milestones": current_count,
                    "future_milestones": future_count,
                    "total_age_groups": len(roadmap)
                },
                "next_milestone": next_milestone
            }
            
        except Exception as e:
            print(f"❌ Error getting milestone overview: {e}")
            raise
    
    def _add_age_highlighting(self, roadmap: List[Dict], current_age: int) -> List[Dict]:
        """Add age-based highlighting (is_current, is_past, is_future) to roadmap."""
        highlighted_roadmap = []
        
        for age_group in roadmap:
            age_start = age_group.get("age_start", 0)
            age_end = age_group.get("age_end", 0)
            
            # Create highlighted copy
            highlighted_group = age_group.copy()
            highlighted_group.update({
                "is_current": age_start <= current_age <= age_end,
                "is_past": current_age > age_end,
                "is_future": current_age < age_start
            })
            
            # Add summary for the age group
            highlighted_group["summary"] = self._create_age_summary(highlighted_group)
            
            highlighted_roadmap.append(highlighted_group)
        
        return highlighted_roadmap
    
    async def _compute_roadmap_legacy(self, child_id: str) -> Dict:
        """Legacy method for computing roadmap on-the-fly (backwards compatibility)."""
        # Get child profile and traits
        report_data = await self.child_repo.load_report(child_id)
        if not report_data:
            raise ValueError(f"Child profile not found: {child_id}")
        
        traits = await self.child_repo.load_traits(child_id)
        if not traits:
            raise ValueError(f"Child traits not found: {child_id}")
        
        # Calculate child's current age
        birthday = report_data.get("birthday", "")
        current_age = self._calculate_child_age_years(birthday)
        child_name = report_data.get("name", f"Child {child_id}")
        
        # Extract Growth & Development genes
        growth_genes = self._extract_gene_ids_from_traits(traits)
        
        if not growth_genes:
            return {
                "child_id": child_id,
                "child_name": child_name,
                "current_age": current_age,
                "roadmap": [],
                "message": "No Growth & Development traits found for this child"
            }
        
        # Get roadmap data (slow legacy method)
        roadmap = await self._build_roadmap(growth_genes, current_age)
        
        return {
            "child_id": child_id,
            "child_name": child_name,
            "current_age": current_age,
            "growth_genes": growth_genes,
            "roadmap": roadmap
        }