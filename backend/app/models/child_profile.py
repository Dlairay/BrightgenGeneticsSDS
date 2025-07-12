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
        for entry in self.report.get("genotype_profile", []):
            rs = entry.get("rs_id")
            genotype = entry.get("genotype")
            rows = self.trait_db[
                (self.trait_db["rs_id"] == rs) &
                (self.trait_db["genotype"] == genotype)
            ]
            for _, row in rows.iterrows():
                matched.append(row.to_dict())
        return matched
    
    def get_derived_age(self) -> Union[int, None]:
        birthday_str = self.report.get("birthday")
        if birthday_str:
            try:
                birth_date = datetime.strptime(birthday_str, '%Y-%m-%d').date()
                today = date.today()
                age = today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))
                return age
            except ValueError:
                print(f"Warning: Could not parse birthday '{birthday_str}' from report. Cannot derive age.")
                return None
        return None