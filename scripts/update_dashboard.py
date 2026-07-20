from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, timedelta
from pathlib import Path
import re
import sys
from urllib.parse import quote

ROOT = Path(__file__).resolve().parent.parent
NOTES_DIR = ROOT / "notes"
README_PATH = ROOT / "README.md"

START_MARKER = "<!-- STUDY_DASHBOARD:START -->"
END_MARKER = "<!-- STUDY_DASHBOARD:END -->"


@dataclass(frozen=True)
class Note:
    path: Path
    study_date: date
    track: str
    topic: str
    status: str


def parse_frontmatter(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return {}

    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}

    result: dict[str, str] = {}
    for line in parts[1].splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        result[key.strip()] = value.strip().strip('"').strip("'")
    return result


def load_notes() -> list[Note]:
    notes: list[Note] = []

    if not NOTES_DIR.exists():
        return notes

    for path in NOTES_DIR.rglob("*.md"):
        metadata = parse_frontmatter(path)

        try:
            study_date = datetime.strptime(metadata.get("date", ""), "%Y-%m-%d").date()
        except ValueError:
            continue

        track = metadata.get("track", "").lower()
        if track not in {"ai-data", "backend"}:
            continue

        notes.append(
            Note(
                path=path,
                study_date=study_date,
                track=track,
                topic=metadata.get("topic", path.stem),
                status=metadata.get("status", "").lower(),
            )
        )

    return notes


def completed_days(notes: list[Note]) -> dict[date, dict[str, Note]]:
    grouped: dict[date, dict[str, Note]] = {}

    for note in notes:
        if note.status != "completed":
            continue
        grouped.setdefault(note.study_date, {})[note.track] = note

    return {
        study_date: tracks
        for study_date, tracks in grouped.items()
        if {"ai-data", "backend"}.issubset(tracks)
    }


def calculate_longest_streak(days: list[date]) -> int:
    if not days:
        return 0

    longest = 1
    current = 1

    for previous, current_day in zip(days, days[1:]):
        if current_day - previous == timedelta(days=1):
            current += 1
            longest = max(longest, current)
        else:
            current = 1

    return longest


def calculate_current_streak(days: list[date]) -> int:
    if not days:
        return 0

    latest = days[-1]
    today = date.today()

    if latest not in {today, today - timedelta(days=1)}:
        return 0

    streak = 1
    day_set = set(days)
    cursor = latest

    while cursor - timedelta(days=1) in day_set:
        cursor -= timedelta(days=1)
        streak += 1

    return streak


def markdown_link(note: Note) -> str:
    relative = note.path.relative_to(ROOT).as_posix()
    encoded = "/".join(quote(part) for part in relative.split("/"))
    topic = note.topic.replace("|", r"\|")
    return f"[{topic}]({encoded})"


def build_dashboard(notes: list[Note]) -> str:
    days_map = completed_days(notes)
    ordered_days = sorted(days_map)

    current_streak = calculate_current_streak(ordered_days)
    longest_streak = calculate_longest_streak(ordered_days)

    lines = [
        START_MARKER,
        "## 📊 Study Dashboard",
        "",
        "| 🔥 현재 스트릭 | 🏆 최장 스트릭 | 📅 완료한 학습일 | 🧠 완료한 질문 |",
        "|---:|---:|---:|---:|",
        (
            f"| **{current_streak}일** | **{longest_streak}일** | "
            f"**{len(ordered_days)}일** | **{len(ordered_days) * 2}개** |"
        ),
        "",
        "### 최근 학습",
        "",
        "| 날짜 | AI·DA | Backend |",
        "|---|---|---|",
    ]

    recent_days = list(reversed(ordered_days[-5:]))

    if not recent_days:
        lines.append("| - | - | - |")
    else:
        for study_date in recent_days:
            tracks = days_map[study_date]
            lines.append(
                f"| {study_date.isoformat()} | "
                f"{markdown_link(tracks['ai-data'])} | "
                f"{markdown_link(tracks['backend'])} |"
            )

    lines.append(END_MARKER)
    return "\n".join(lines)


def update_readme() -> None:
    readme = README_PATH.read_text(encoding="utf-8")
    dashboard = build_dashboard(load_notes())

    pattern = re.compile(
        re.escape(START_MARKER) + r".*?" + re.escape(END_MARKER),
        flags=re.DOTALL,
    )

    if not pattern.search(readme):
        raise RuntimeError("Dashboard markers were not found in README.md")

    README_PATH.write_text(pattern.sub(dashboard, readme), encoding="utf-8")
    print("README dashboard updated.")


if __name__ == "__main__":
    try:
        update_readme()
    except Exception as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
