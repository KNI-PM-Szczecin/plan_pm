import argparse
import os
import json
from typing import Any
from dotenv import load_dotenv
from supabase import create_client
import datetime
import time

# Database structure:
# Building
# Classes
# Programs
# Rooms
# Teachers
# Teachersclasses

load_dotenv()

_env_mode_path = os.path.join(os.path.dirname(__file__), "..", ".env_mode")
_prefix = "TEST_" if open(_env_mode_path).read().strip() == "test" else ""

_PAGE_SIZE = 1000

def _fetch_all(query_builder, page_size: int = _PAGE_SIZE) -> list:
    """Fetch all rows from a Supabase query by paginating in chunks of page_size."""
    rows = []
    offset = 0
    while True:
        batch = query_builder.range(offset, offset + page_size - 1).execute()
        rows.extend(batch.data)
        if len(batch.data) < page_size:
            break
        offset += page_size
    return rows

class json2db:
    db: Any
    data: dict
    
    def __init__(self, input, dry_run=False, clear=False):
        self.dry_run = dry_run
        self.clear = clear
        print("Json2DB loaded.")
        with open(input, encoding="utf8") as file:
            self.data = json.loads(file.read())
        
        
    def load_env(self):
        # Load environment variables and create a db connection
        url = os.environ.get(f"{_prefix}SUPABASE_URL")
        key = os.environ.get(f"{_prefix}SUPABASE_KEY")
        service_key = os.environ.get(f"{_prefix}SUPABASE_SERVICE_KEY")

        if not url or not key:
            raise EnvironmentError("SUPABASE_URL and SUPABASE_KEY are required. Add them to your .env file.")
        if not service_key:
            raise EnvironmentError("SUPABASE_SERVICE_KEY is required for clear_db(). Add it to your .env file.")

        print("Got url: ", url)

        self.db = create_client(url, key)
        self.admin_db = create_client(url, service_key)
        
    def clear_db(self):
        self.admin_db.table("teachersclasses").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
        self.admin_db.table("classes").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
        self.admin_db.table("programs").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
        self.admin_db.table("rooms").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
        self.admin_db.table("teachers").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
        self.admin_db.table("building").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
        
        
    def load_teachers(self):
        print("Loading teachers.")
        query = []
        for teacher in self.data["teachers"]:
            query.append({
                "fullName": teacher["fullName"],
                "title": teacher["title"]
            })
        
        _ = self.db.table("teachers").upsert(query, on_conflict="fullName, title").execute()
        print("Done.")
    
    def load_buildings(self):
        print("Loading buildings.")
        query = []
        for building in self.data["building"]:
            query.append({
                "name": building
            })

        _ = self.db.table("building").upsert(query, on_conflict="name").execute()
        print("Done")
    
    def load_rooms(self):
        print("Loading rooms")
        
        response = self.db.table("building").select("id, name").execute()
        buildings = {v['name']: v['id'] for v in response.data}
        
        query = []
        for room in self.data["rooms"]:
            if room["building"] != None:
                building_name = self.data["building"][room["building"]]
                id = buildings.get(building_name)
                
                query.append({
                    "name": room["room"],
                    "building": id
                    })
            else:
                query.append({
                    "name": room["room"],
                    "building": None
                    })
                
        _ = self.db.table("rooms").upsert(query, on_conflict="name, building").execute()
                
        print("Done")
    
    def load_programs(self):
        print("Loading programs")
        
        current_year: int = datetime.datetime.now().year
        current_month: int = datetime.datetime.now().month
        
        is_winter_semester: bool = True if current_month >= 10 else False
         
        query: list = []
        for program in self.data["programs"]:
            # Calculate shitty academic year to current year
            programs_year: int = int(program["academic_year"].split(" ")[0].split("/")[0])
            
            programs_year = programs_year
            current_academic_start_year = current_year if is_winter_semester else current_year - 1
            
            if programs_year > current_academic_start_year:
                final_year = 0

            else:
                final_year = current_academic_start_year - programs_year + 1
            
            query.append({
                "name": program["name"],
                "programType": program["program_type"],
                "degreeLevel": program["degree_level"],
                "language": program["language"],
                "academicYear": program["academic_year"],
                "courseLength": float(program["course_length"]),
                "year": final_year
            })
        _ = self.db.table("programs").upsert(query, on_conflict="name, programType, degreeLevel, language, academicYear").execute()
        print("Done")
        
    
    def load_classes(self):
        print("Loading classes")

        query = []
        programs_data = _fetch_all(self.db.table("programs").select("id, name, academicYear, language, programType, courseLength, degreeLevel"))
        programs_map = {v["id"] : [v["name"], v["academicYear"], v["language"], v["programType"], v["courseLength"], v["degreeLevel"]] for v in programs_data}

        buildings_data = _fetch_all(self.db.table("building").select("id, name"))
        buildings_map = {v["name"]: v["id"] for v in buildings_data}

        rooms_data = _fetch_all(self.db.table("rooms").select("id, name, building"))
        room_map = {(v["name"], v["building"]): v["id"] for v in rooms_data}

        processed_class_keys = set()

        for sclass in self.data["classes"]:
            found_program = self.data["programs"][sclass["program"]]
            program_name = found_program["name"]
            program_type = found_program["program_type"]
            degree_level = found_program["degree_level"]
            academic_year = found_program["academic_year"]
            course_length = float(found_program["course_length"])
            language = found_program["language"]

            found_program_id = None
            program = [program_name, academic_year, language, program_type, course_length, degree_level]
            for program_id, program_value in programs_map.items():
                if (program_value == program):
                    found_program_id = program_id

            if (found_program_id == None):
                print("Nie znaleziono ID dla programu - niedobrze")
                continue

            room = sclass["room"]
            room_id = None
            if (room != None):
                room_data = self.data["rooms"][sclass["room"]]
                room_name = room_data["room"]
                b_idx = room_data.get("building")
                building_uuid = buildings_map.get(self.data["building"][b_idx]) if b_idx is not None else None
                room_id = room_map.get((room_name, building_uuid))

            subject = sclass["subject"]
            subject_name = self.data["subjects"][subject]

            start_time_formatted = datetime.datetime.fromtimestamp(int(sclass["startTime"])).strftime("%Y-%m-%dT%H:%M:%S")
            end_time_formatted = datetime.datetime.fromtimestamp(int(sclass["endTime"])).strftime("%Y-%m-%dT%H:%M:%S")

            current_class_key = (subject_name, start_time_formatted, sclass["group"], program_name)

            if current_class_key in processed_class_keys:
                # print(f"Pominięto duplikat klasy w JSON: {current_class_key}")
                continue
            processed_class_keys.add(current_class_key)

            query.append({
                "startTime": start_time_formatted,
                "endTime": end_time_formatted,
                "program": found_program_id,
                "subject": subject_name,
                "group": sclass["group"],
                "room": room_id,
                "notes": sclass["notes"]
            })

        _ = self.db.table("classes").upsert(query, on_conflict="subject, startTime, group, program").execute()
        print("Done")

    def load_teachers_classes(self):
        print("Loading teachers/classes")

        classes_data = _fetch_all(self.db.table("classes").select("id, subject, group, startTime"))
        teachers_data = _fetch_all(self.db.table("teachers").select("id, fullName"))

        classes_map = {
            (v["subject"], v["group"], v["startTime"]): v["id"]
            for v in classes_data
        }

        teachers_map = {v["fullName"]: v["id"] for v in teachers_data}

        query = []
        added_links = set() 

        for tc in self.data["teachersclasses"]:
            found_class_json = self.data["classes"][tc["class"]]

            subject = self.data["subjects"][found_class_json["subject"]]
            group = found_class_json["group"]
            start_time = datetime.datetime.fromtimestamp(int(found_class_json["startTime"])).strftime("%Y-%m-%dT%H:%M:%S")

            unique_class_key = (subject, group, start_time)

            found_class_id = classes_map.get(unique_class_key)

            if (found_class_id == None):
                print(f"Nie znaleziono ID dla klasy: {unique_class_key}")
                continue

            for teacher_index in set(tc["teachers"]): 
                teacher_fullname = self.data["teachers"][teacher_index]["fullName"]
                teacher_id = teachers_map.get(teacher_fullname)

                if teacher_id:
                    link_key = (teacher_id, found_class_id)
                    if link_key not in added_links: 
                        query.append({
                            "teachers": teacher_id,
                            "classes": found_class_id
                        })
                        added_links.add(link_key)

        if query:
            _ = self.db.table("teachersclasses").upsert(query, on_conflict="teachers, classes").execute()
        print("Done")
            
    def run(self):
        print("Executing json2db.py")

        if self.dry_run:
            print("Tryb dry-run — pominięto zapis do bazy danych")
            print(json.dumps(self.data, ensure_ascii=False, indent=2))
            return

        start_time = time.time()
        self.load_env()
        if self.clear:
            self.clear_db()
        self.load_teachers()
        self.load_buildings()
        self.load_rooms()
        self.load_programs()
        self.load_classes()
        self.load_teachers_classes()
        end_time = time.time()
        print(f"Done. Total execution time: {end_time - start_time:.2f} seconds")
            
        


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Wczytaj dane z parser.json do bazy danych")
    parser.add_argument(
        "--input", default="./output/parser.json",
        help="Ścieżka do pliku wejściowego parser.json (domyślnie: ./output/parser.json)",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Wyświetl dane bez zapisywania do bazy danych",
    )
    parser.add_argument(
        "--clear", action="store_true",
        help="Wyczyść bazę danych przed zapisem (domyślnie: wyłączone)",
    )
    args = parser.parse_args()

    App = json2db(input=args.input, dry_run=args.dry_run, clear=args.clear)
    App.run()