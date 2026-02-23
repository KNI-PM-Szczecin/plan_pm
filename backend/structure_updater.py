import os
import xml.etree.ElementTree as ET
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

FACULTIES_TABLE_NAME: str = "faculties" # Wydziały
DEGREE_COURSES_TABLE_NAME: str = "degree_courses" # Kierunki
SPECIALISATIONS_TABLE_NAME: str = "specialisations" # Specjalizacje

# Vibecoded the shit out of this function. It looks okay i think? xD
def parse_university_structure(xml_path: str = "structure.xml") -> list[dict]:
    root = ET.parse(Path(xml_path)).getroot()
    data: list[dict] = []

    for faculty in root.findall("faculty"):
        faculty_name = faculty.get("name", "Unknown faculty")
        faculty_entry: dict = {"name": faculty_name, "degree_courses": []}

        for degree_course in faculty.findall("degree_course"):
            course_name = degree_course.get("name", "Unknown degree course")
            specialisations: list[str] = []

            for specialisation in degree_course.findall("specialisation"):
                spec_name = (specialisation.text or "").strip()
                if spec_name:
                    specialisations.append(spec_name)

            faculty_entry["degree_courses"].append(
                {"name": course_name, "specialisations": specialisations}
            )

        data.append(faculty_entry)

    return data

# Vibecoded the shit out of this function. It looks okay i think? xD
def propagate_structure_to_db(db, structure: list[dict]) -> None:
    for faculty in structure:
        faculty_row = (
            db.table(FACULTIES_TABLE_NAME)
            .insert({"name": faculty["name"]})
            .execute()
        )
        faculty_id = faculty_row.data[0]["id"]

        for degree_course in faculty["degree_courses"]:
            degree_course_row = (
                db.table(DEGREE_COURSES_TABLE_NAME)
                .insert(
                    {
                        "name": degree_course["name"],
                        "faculty_id": faculty_id,
                    }
                )
                .execute()
            )
            degree_course_id = degree_course_row.data[0]["id"]

            for specialisation_name in degree_course["specialisations"]:
                (
                    db.table(SPECIALISATIONS_TABLE_NAME)
                    .insert(
                        {
                            "name": specialisation_name,
                            "degree_course_id": degree_course_id,
                        }
                    )
                    .execute()
                )


def clear_structure_tables(db) -> None:
    # Delete previous structure as it is shit
    db.table(SPECIALISATIONS_TABLE_NAME).delete().gte("id", 0).execute()
    db.table(DEGREE_COURSES_TABLE_NAME).delete().gte("id", 0).execute()
    db.table(FACULTIES_TABLE_NAME).delete().gte("id", 0).execute()


url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_KEY")

if (url != None and key != None):
    db = create_client(url, key)

    try:
        clear_structure_tables(db)
    except Exception as exc:
        raise RuntimeError(
            "Failed to clear structure tables. Check Supabase delete policies/RLS."
        ) from exc

    parsed_structure = parse_university_structure("structure.xml")
    propagate_structure_to_db(db, parsed_structure)
    print("Structure propagated to Supabase.")
