from datetime import datetime
from os import path
from os import path
from json import loads as loadJSON, dumps as dumpJSON
from dataclasses import dataclass, field

PROGRAM_TYPE = ["S", "N"]
DEGREE_LEVEL = ["lic", "mgr", "inż."]
LANGUAGE = ["POL", "ANG"]
ACADEMIC_YEAR = ["zima", "lato"]

BUILDINGS = ["WChrobrego", "HPobożnego", "Willowa", "Szczerbcow", "Żołnierska"]

MAP = {"Plan dla toku" : "program", "Przedmiot" : "subject", "Grupy" : "group", "Sala" : "room", "Prowadzący" : "teacher", "Uwagi" : "notes"}

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

def progressBar(progress, max, bar=40):
    if(progress>=max-1):
        print(f"\r✅ [{bar*'█'}] {max}/{max} 100%              \n")
        return
    diff = int((max-progress)/max*bar)
    print(f"\r❌ [{(bar-diff)*'█'}{diff*'░'}] {progress}/{max} {progress/max*100:.1f}%              ", end='')
    return False

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
        length = len(self.tok)
        for tmp, i in enumerate(self.tok):
            progressBar(tmp, length)
            self.breakDownTok(i)

        print("Cleaning up tok strings")
        length = len(self.sched.programs)
        self.sched.programs = [self.tokStringToDic(tok) for i, tok in enumerate(self.sched.programs) if not progressBar(i, length)]
    
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
        
        for program_type in PROGRAM_TYPE:
            if f' {program_type} ' in original:
                tok["program_type"] = program_type
                break
            
        for language in LANGUAGE:
            if f' {language} ' in original:
                tok["language"] = language
                break
            
        for degree_level in DEGREE_LEVEL:
            if f'{degree_level} ' in original:
                tok["degree_level"] = degree_level
                break
            
        remaining = original
        
        try:
            remaining = remaining.replace(f' {tok["program_type"]} ', ' ')
            remaining = remaining.replace(f' {tok["language"]} ', ' ')
            parts = remaining.split(f'{tok["degree_level"]} ')
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
        if teacher == "":
            return []
        prof = teacher.find("prof. ", 1)
        dr = teacher.find("dr ", 7)
        mgr = teacher.find("mgr ", 1)
    
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
    
        t.append(teacher.strip())
    
        return t

    @staticmethod
    def parseRooms(room):
        if not room:
            return []
    
        parsed_rooms = []
        for r in room.split(","):
            r = r.strip()
            if r not in parsed_rooms:
                parsed_rooms.append(r)
        return parsed_rooms


    # Important!!! This will only work correctly if your system's date locale is Polish.
    @staticmethod
    def convertDateToTimestamp(date, start, end):
        date = date.split(".")
        date = datetime(int(date[0]), int(date[1]), int(date[2].split(" ")[0]))
        start = start.split(":")
        end = end.split(":")
    
        start = date.replace(hour=int(start[0]), minute=int(start[1]), second=0).timestamp()
        end = date.replace(hour=int(end[0]), minute=int(end[1]), second=0).timestamp()
    
        return start, end


    def normalizeClasses(self, classes, teachers, rooms):
        teacher_to_idx = {teacher: i for i, teacher in enumerate(teachers)}
        room_to_idx = {room: i for i, room in enumerate(rooms)}
        
        length = len(classes)
        return [{k: v for k, v in c.items() if k not in {"Liczba godzin", "Forma zajęć", "Forma zaliczenia"}} | {"Prowadzący": [teacher_to_idx[x] for x in self.parseTeachers(c["Prowadzący"])], "Sala": (room_to_idx[c["Sala"]] if c["Sala"] in rooms else None)} for num, c in enumerate(classes) if not progressBar(num, length) ]
    

    @staticmethod
    def breakDownTeachers(teachers):
        length=len(teachers)
        for i, t in enumerate(teachers):
            t = t.split(" ")
            teachers[i] = {"title": " ".join(t[:-2]), "fullName": " ".join(t[-2:])}
            progressBar(i, length)
        return teachers
    
    def breakDownBuildings(self, rooms):
        buildings = []
        length=len(rooms)
        for i, room in enumerate(rooms):
            r, b = self.breakDownRoom(room)
            t = {"building" : b, "room" : r}
            if not b:
                rooms[i] = t
                continue
            if b not in buildings:
                buildings.append(b)
            t["building"] = buildings.index(b)
            rooms[i] = t
            progressBar(i, length)
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
            print(self.sched.programs[0])
            print(self.sched.classes[535])
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