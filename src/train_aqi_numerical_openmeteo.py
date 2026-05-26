import sys
from pathlib import Path

# Add AQI src to path
aqi_src = Path(__file__).parent.parent / "AQI" / "src"
sys.path.insert(0, str(aqi_src))

from train_aqi_numerical_openmeteo import main

if __name__ == "__main__":
    main()
