from datetime import datetime
from zoneinfo import ZoneInfo
from os import path
from json import loads as loadJSON, dumps as dumpJSON
from dataclasses import dataclass, field
from rich.progress import Progress

# University times are Warsaw local; pin the zone so timestamps are identical
# regardless of the host machine's timezone (json2db reads them back in the
# same zone). Avoids cross-machine drift in the stored start/end times.
WARSAW_TZ = ZoneInfo("Europe/Warsaw")

from console_setup import force_utf8_output

force_utf8_output()

PROGRAM_TYPE = ["S", "N"]
DEGREE_LEVEL = ["lic", "mgr", "inż."]
LANGUAGE = ["POL", "ANG"]
ACADEMIC_YEAR = ["zima", "lato"]

BUILDINGS = ["WChrobrego", "HPobożnego", "Willowa", "Szczerbcow", "Żołnierska"]

MAP = {"Plan dla toku" : "program", "Przedmiot" : "subject", "Grupy" : "group", "Sala" : "room", "Prowadzący" : "teacher", "Uwagi" : "notes"}

DEBUG = False

### DEBUG TOOL
def printTok(tok):
    if not DEBUG:
        return
    print("========================================")
    print(f"Plan dla toku: {tok['Plan dla toku']}")
    print(f"Przedmiot: {tok['Przedmiot']}")
    print(f"Grupy: {tok['Grupy']}")
    print(f"Sala: {tok['Sala']}")
    print(f"Prowadzący: {tok['Prowadzący']}")
    print(f"Data zajęć: {tok['Data zajęć']}")
    print(f"Od: {tok['Czas od']}")
    print(f"Do: {tok['Czas do']}")
    print("========================================\n")

def printConvertedTok(tok):
    if not DEBUG:
        return
    print("========================================")
    print(f"Plan dla toku: {tok['Plan dla toku']}")
    print(f"Przedmiot: {tok['Przedmiot']}")
    print(f"Grupy: {tok['Grupy']}")
    print(f"Sala: {tok['Sala']}")
    print(f"Prowadzący: {tok['Prowadzący']}")
    print(f"Od: {datetime.fromtimestamp(tok['startTime']).strftime('%Y-%m-%d %H:%M')} ({tok["startTime"]})")
    print(f"Do: {datetime.fromtimestamp(tok['endTime']).strftime('%Y-%m-%d %H:%M')} ({tok["endTime"]})")
    print("========================================\n")

@dataclass
class ScheduleData:
    programs: list
    classes: list
    teachers: list
    subjects: list
    rooms: list
    buildings: list

    _programs_set: set = field(default_factory=set, init=False, repr=False)
    _teachers_set: set = field(default_factory=set, init=False, repr=False)
    _subjects_set: set = field(default_factory=set, init=False, repr=False)
    _rooms_set: set = field(default_factory=set, init=False, repr=False)

def _with_progress(items, label):
    """Yield items while showing a rich progress bar (matches mapper/scrapper)."""
    items = list(items)
    with Progress() as p:
        task = p.add_task(label, total=len(items))
        for item in items:
            yield item
            p.update(task, advance=1)

class Parser:
    def __init__(self, debug=False, input = "scrapper.json", output = "./output", outputFile="parser.json"):
        self.DEBUG = debug
        self.input = input
        self.output = output
        self.inputFile = output+'/'+input
        self.outputFile = output+'/'+outputFile
        
        print(f'\n\nZaczynam parsowanie danych w pliku {path.abspath(self.inputFile)}\n')
        self.sched = ScheduleData([], [], [], [], [], [])
        self.tok = self.readJson()


    def readJson(self):
        with open(self.inputFile, "r", encoding="utf-8") as file:
            return loadJSON(file.read())


    def getTokAndPlan(self):
        print("Loading the JSON")
        for i in _with_progress(self.tok, "Wczytywanie toków..."):
            self.breakDownTok(i)

        print("Cleaning up tok strings")
        self.sched.programs = [
            self.tokStringToDic(tok)
            for tok in _with_progress(self.sched.programs, "Czyszczenie toków...")
        ]
    
        print("Normalizing classes")
        self.sched.classes = self.normalizeClasses(self.sched.classes, self.sched.teachers, self.sched.rooms)
    
        print("Normalizing teachers")
        self.sched.teachers = self.breakDownTeachers(self.sched.teachers)
    
        print("Normalizing buildings and rooms")
        self.sched.rooms, self.sched.buildings = self.breakDownBuildings(self.sched.rooms)




    @staticmethod
    def tokStringToDic(tokString):
        tok = {
            "name": "",
            "program_type": "",
            "degree_level": "",
            "language": LANGUAGE[0],
            "academic_year": "",
            "course_length": 0
        }
        
        original = tokString
        

        for degree_level in DEGREE_LEVEL:
            if f'{degree_level} ' in original:
                tok["degree_level"] = degree_level
                break

        if not tok["degree_level"]:
            print(f"Error processing course (unknown degree level): {original}")
            tok["name"] = original.strip()
            return tok

        temp = original.split(tok['degree_level'], 1)

        for program_type in PROGRAM_TYPE:
            if f'{program_type} ' in temp[0][-2:]:
                tok["program_type"] = program_type
                temp[0] = temp[0][:-3]
                break


        for language in LANGUAGE:
            if f'{language}' in temp[0][-6:].upper():
                tok["language"] = language
                temp[0] = temp[0].split(language)[0].strip()
                break

        try:
            parts = temp
            tok["name"] = parts[0].strip()
            length_season = parts[1].strip().split(' ')
            tok["course_length"] = length_season[0]
            tok["academic_year"] = ' '.join(length_season[1:])
        except:
            print(f"Error processing course: {original}")
    
        return tok



    def breakDownTok(self, tok):
        if tok["Plan dla toku"] not in self.sched._programs_set:
            self.sched.programs.append(tok["Plan dla toku"])
            self.sched._programs_set.add(tok["Plan dla toku"])
        teachArray = self.parseTeachers(tok["Prowadzący"])
        for x in teachArray:
            if x and x not in self.sched._teachers_set:
                self.sched.teachers.append(x)
                self.sched._teachers_set.add(x)
        if tok["Sala"]:
            for s in self.parseRooms(tok["Sala"]):
                if s not in self.sched.rooms:
                    self.sched.rooms.append(s)
                    self.sched._rooms_set.add(s)
        if tok["Przedmiot"] not in self.sched._subjects_set:
            self.sched.subjects.append(tok["Przedmiot"])
            self.sched._subjects_set.add(tok["Przedmiot"])

        tok["Plan dla toku"] = self.sched.programs.index(tok["Plan dla toku"])
        tok["Przedmiot"] = self.sched.subjects.index(tok["Przedmiot"])
        tok["startTime"], tok["endTime"] = self.convertDateToTimestamp(tok.pop("Data zajęć"), tok.pop("Czas od"), tok.pop("Czas do"))

        if "," in tok["Grupy"]:
            groups = tok["Grupy"].split(",")
            for i in groups:
                t = tok.copy()
                t["Grupy"] = i.strip()
                self.sched.classes.append(t)
        else:
            self.sched.classes.append(tok)


    def parseTeachers(self, teacher):
        teacher = teacher.strip()
        if not teacher:
            return []
        prof = teacher.find("prof. ", 1)
        dr = teacher.find("dr ", 7)
        mgr = teacher.find("mgr ", 1)

        # "kpt. ż. w." is a maritime title that can appear both as part of a compound
        # academic title (e.g. "mgr inż. kpt. ż. w.") and as a standalone title for
        # a second teacher. Distinguish by checking what precedes it:
        # - preceded by '.' → part of compound title → find second occurrence
        # - preceded by a name word (no dot) → starts a new teacher
        first_kpt = teacher.find("kpt. ")
        if first_kpt == -1:
            kpt = -1
        elif first_kpt == 0:
            kpt = teacher.find("kpt. ", 5)
        else:
            before = teacher[:first_kpt].rstrip()
            kpt = teacher.find("kpt. ", first_kpt + 5) if before.endswith('.') else first_kpt

        t = []

        if prof != -1:
            t += self.parseTeachers(teacher[prof:])
            teacher = teacher[:prof]
        elif dr != -1:
            t += (self.parseTeachers(teacher[dr:]))
            teacher = teacher[:dr]
        elif mgr != -1:
            t += (self.parseTeachers(teacher[mgr:]))
            teacher = teacher[:mgr]
        elif kpt != -1:
            t += (self.parseTeachers(teacher[kpt:]))
            teacher = teacher[:kpt]

        remaining = teacher.strip()
        if remaining:
            t.append(remaining)

        return t

    @staticmethod
    def parseRooms(room):
        if not room:
            return []
    
        parsed_rooms = []
        for r in room.split(", "):
            r = r.strip()
            if r not in parsed_rooms:
                parsed_rooms.append(r)
        return parsed_rooms


    @staticmethod
    def convertDateToTimestamp(date, start, end):
        date = date.split(".")
        date = datetime(int(date[0]), int(date[1]), int(date[2].split(" ")[0]), tzinfo=WARSAW_TZ)
        start = start.split(":")
        end = end.split(":")

        start = date.replace(hour=int(start[0]), minute=int(start[1]), second=0).timestamp()
        end = date.replace(hour=int(end[0]), minute=int(end[1]), second=0).timestamp()

        return start, end


    def normalizeClasses(self, classes, teachers, rooms):
        teacher_to_idx = {teacher: i for i, teacher in enumerate(teachers)}
        room_to_idx = {room: i for i, room in enumerate(rooms)}

        def sala_idx(sala_str):
            parsed = self.parseRooms(sala_str)
            return room_to_idx.get(parsed[0]) if parsed else None

        return [{k: v for k, v in c.items() if k not in {"Liczba godzin", "Forma zajęć", "Forma zaliczenia"}} | {"Prowadzący": [teacher_to_idx[x] for x in self.parseTeachers(c["Prowadzący"])], "Sala": sala_idx(c["Sala"])} for c in _with_progress(classes, "Normalizacja zajęć...")]
    

    @staticmethod
    def breakDownTeachers(teachers):
        result = []
        for teacher in _with_progress(teachers, "Przetwarzanie prowadzących..."):
            parts = teacher.split()
            if not parts:
                continue
            result.append({
                "title": " ".join(parts[:-2]),
                "fullName": " ".join(parts[-2:]),
            })
        return result

    def breakDownBuildings(self, rooms):
        buildings = []
        for i, room in enumerate(_with_progress(rooms, "Przetwarzanie budynków...")):
            r, b = self.breakDownRoom(room)
            t = {"building" : b, "room" : r}
            if not b:
                rooms[i] = t
                continue
            if b not in buildings:
                buildings.append(b)
            t["building"] = buildings.index(b)
            rooms[i] = t
        return rooms, buildings
    
    @staticmethod
    def breakDownRoom(room):
        b = None
        room = room.split(" ")
        if room[0] in BUILDINGS:
            if room[1][0] == 'B' and room[1][1].isdigit():
                b = " ".join(room[:2])
                room = room[2:]
            else:
                b = room[0]
                room = room[1:]
            room = " ".join(room)
        else:
            room = " ".join(room)
        return room, b
    
    def run(self):
        self.getTokAndPlan()
        for i, cl in enumerate(self.sched.classes):
            for old in MAP:
                if MAP[old]:
                    self.sched.classes[i][MAP[old]] = self.sched.classes[i].pop(old)
                else:
                    self.sched.classes[i].pop(old)

        teachersclasses = []

        for i, cl in enumerate(self.sched.classes):
            teachersclasses.append({"class": i, "teachers": self.sched.classes[i].pop("teacher")})

        if self.DEBUG:
            print()
            if self.sched.programs:
                print(self.sched.programs[0])
            if self.sched.classes:
                print(self.sched.classes[0])
            if self.sched.teachers:
                print(self.sched.teachers[0])

        print(f'Zapisuję dane do {path.abspath(self.outputFile)}')
        with open (self.outputFile, "w", encoding="utf-8") as file:
            file.write(dumpJSON({
                "programs": self.sched.programs,
                "classes": self.sched.classes,
                "teachers": self.sched.teachers,
                "teachersclasses": teachersclasses,
                "subjects": self.sched.subjects,
                "rooms": self.sched.rooms,
                "building": self.sched.buildings
            }, indent=4, ensure_ascii=False).replace("    ", "\t"))
            print(f'Dane zostały zapisane pomyślnie do {path.abspath(self.outputFile)}')
