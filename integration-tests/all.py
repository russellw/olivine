import os
import subprocess
from pathlib import Path

def run_all_tests(test_root: Path):
    results = []
    # Find all directories that contain test.py
    for test_dir in test_root.iterdir():
        if not test_dir.is_dir() or test_dir.name == 'common':
            continue
            
        test_script = test_dir / 'test.py'
        if not test_script.exists():
            continue
            
        print(f"Running tests in {test_dir.name}")
        try:
            # Run each test in its own process
            result = subprocess.run(
                ['python', str(test_script)],
                cwd=test_dir,
                capture_output=True,
                text=True
            )
            results.append({
                'test': test_dir.name,
                'success': result.returncode == 0,
                'output': result.stdout,
                'error': result.stderr
            })
        except Exception as e:
            results.append({
                'test': test_dir.name,
                'success': False,
                'error': str(e)
            })
            
    return results

if __name__ == '__main__':
    test_root = Path(__file__).parent
    results = run_all_tests(test_root)
    
    # Print summary
    print("\nTest Results:")
    for r in results:
        status = "✓" if r['success'] else "✗"
        print(f"{status} {r['test']}")
        if not r['success']:
            print(f"  Error: {r['error']}")