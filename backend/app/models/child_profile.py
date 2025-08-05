from typing import Dict, List, Optional, Union
from datetime import datetime, date
import pandas as pd


class ChildProfile:
    def __init__(self, child_id: str, trait_db: pd.DataFrame):
        self.child_id = child_id
        self.trait_db = trait_db
        self._report_data: Optional[Dict] = None
        self._traits_data: Optional[List[Dict]] = None
        self._logs_data: Optional[List[Dict]] = None
    
    @property
    def report(self) -> Dict:
        return self._report_data or {}
    
    @report.setter
    def report(self, value: Dict):
        self._report_data = value
    
    @property
    def traits(self) -> List[Dict]:
        return self._traits_data or []
    
    @traits.setter
    def traits(self, value: List[Dict]):
        self._traits_data = value
    
    @property
    def logs(self) -> List[Dict]:
        return self._logs_data or []
    
    @logs.setter
    def logs(self, value: List[Dict]):
        self._logs_data = value
    
    def match_traits(self) -> List[Dict]:
        matched = []
        genotype_profile = self.report.get("genotype_profile", [])
        
        for entry in genotype_profile:
            rs = entry.get("rs_id")
            genotype = entry.get("genotype")
            
            rows = self.trait_db[
                (self.trait_db["rs_id"] == rs) &
                (self.trait_db["genotype"] == genotype)
            ]
            
            if not rows.empty:
                for _, row in rows.iterrows():
                    trait_dict = row.to_dict()
                    # Ensure archetype field exists (it should already be in the data)
                    if "archetype" not in trait_dict:
                        trait_dict["archetype"] = ""  # Only add if missing
                    matched.append(trait_dict)
        
        return matched
    
    def get_derived_age(self) -> Union[int, None]:
        birthday_str = self.report.get("birthday")
        if birthday_str:
            try:
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
                        birth_date = datetime.strptime(birthday_str, date_format).date()
                        break
                    except ValueError:
                        continue
                
                if birth_date is None:
                    print(f"Warning: Could not parse birthday '{birthday_str}' from report. Cannot derive age.")
                    return None
                
                today = date.today()
                age = today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))
                return age
            except Exception as e:
                print(f"Warning: Error parsing birthday '{birthday_str}' from report: {e}")
                return None
        return None