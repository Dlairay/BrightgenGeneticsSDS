from childprofile import create_child_profile
from planner_agent.agent import run_for_child

import asyncio


sample_child_data = "backend/data/sample_upload.json"

# Create a child profile from the sample data

# child_1 = create_child_profile(sample_child_data)


#check-ins and reevaluate

asyncio.run(run_for_child(1))