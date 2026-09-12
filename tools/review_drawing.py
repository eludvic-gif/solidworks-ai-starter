"""Review a local JSON report, never CAD or a machine. No network access.
Exit 0 = structured review completed, NOT approval; 2 = blocked review.
The output path must be new. Registry is the curated file shipped with the kit.
"""
import argparse
import json
from pathlib import Path
from drawing_review import review

ROOT = Path(__file__).resolve().parents[1]


def load_json(path):
    if path.stat().st_size > 2_000_000:
        raise ValueError('JSON input exceeds 2 MB')
    def reject_constant(value):
        raise ValueError('Nonfinite JSON constant: ' + value)
    def unique_keys(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError('Duplicate JSON key: ' + key)
            result[key] = value
        return result
    return json.loads(path.read_text(encoding='utf-8-sig'),
                      parse_constant=reject_constant, object_pairs_hook=unique_keys)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args(argv)
    if args.output.exists():
        raise FileExistsError('Refuse overwrite: ' + str(args.output))
    try:
        report = load_json(args.input)
        registry = load_json(ROOT / 'standards/registry.json')
        result = review(report, registry)
    except (ValueError, TypeError, KeyError, OverflowError, RecursionError) as exc:
        result = {'status': 'fail', 'release': 'BLOCKED', 'iso_compliant': None,
                  'findings': [{'rule': 'schema', 'status': 'fail',
                                'detail': 'Invalid input structure: ' + type(exc).__name__}]}
    with args.output.open('x', encoding='utf-8') as stream:
        json.dump(result, stream, indent=2, ensure_ascii=False, allow_nan=False)
        stream.write('\n')
    print(result['status'], 'release=' + result['release'])
    return 2 if result['status'] == 'fail' else 0


if __name__ == '__main__':
    raise SystemExit(main())
