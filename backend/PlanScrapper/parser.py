from datetime import datetime

PROGRAM_TYPE = ["S", "N"]
DEGREE_LEVEL = ["lic", "mgr", "inż."]
LANGUAGE = ["POL", "ANG"]
ACADEMIC_YEAR = ["zima", "lato"]

# Important!!! This will only work correctly if your system's date locale is Polish.
def convertDateToTimestamp(date, start, end):
    timestamp = {
        "start": 0,
        "end": 0
    }
    
    date = date.split(".")
    date = datetime(int(date[0]), int(date[1]), int(date[2].split(" ")[0]))
    start = start.split(":")
    end = end.split(":")

    timestamp["start"] = date.replace(hour=int(start[0]), minute=int(start[1]), second=0).timestamp()
    timestamp["end"] = date.replace(hour=int(end[0]), minute=int(end[1]), second=0).timestamp()

    return timestamp

def parseTeachers(teacher):
    if teacher == "":
        return []
    prof = teacher.find("prof. ", 1)
    dr = teacher.find("dr ", 7)
    mgr = teacher.find("mgr ", 1)


    teachers = []

    if prof != -1:
        teachers += parseTeachers(teacher[prof:])
        teacher = teacher[:prof]
    elif dr != -1:
        teachers += (parseTeachers(teacher[dr:]))
        teacher = teacher[:dr]
    elif mgr != -1:
        teachers += (parseTeachers(teacher[mgr:]))
        teacher = teacher[:mgr]

    teachers.append(teacher)

    return teachers

def getTokAndPlan(json):
    programs = []
    classes = []
    teachers = []
    toknum = -1
    for i in json:
            obj = eval(i[:-1])
            if obj["Plan dla toku"] not in programs:
                programs.append(obj["Plan dla toku"])
                toknum += 1
            if obj["Prowadzący"] not in teachers:
                teachers.append(obj["Prowadzący"])
            obj["Plan dla toku"] = toknum
            obj["timestamp"] = convertDateToTimestamp(obj.pop("Data zajęć"), obj.pop("Czas od"), obj.pop("Czas do"))

            classes.append(obj)
    
    temp = []
    for i, teacher in enumerate(teachers):
        for i in parseTeachers(teacher):
            if i in temp:
                continue
            if "prof." in i:
                temp.append(i)
            elif "dr " in i:
                temp.append(i)
            elif "mgr " in i:
                temp.append(i)
            else:
                print(f"Unknown teacher format: {i}")

    return programs, classes, temp

def readJson():
    with open("plany.json", "r", encoding="utf-8") as file:
        json = file.read().splitlines()
        programs, classes, teachers = getTokAndPlan(json[1:])

        return programs, classes, teachers

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

programs, classes, teachers = readJson()
programs = [tokStringToDic(tok) for tok in programs]
classes = [{**c, "Prowadzący": " ".join(str(teachers.index(x)) for x in parseTeachers(c["Prowadzący"]))} for c in classes]

with open("flows.json", "r", encoding="utf-8") as file:
    flows = file.read().splitlines()
    flows = [tokStringToDic(i[12:]) for i in flows[1:-1]]

for program in programs:
    if program in flows:
        print("Flow already exists in programs:", flow)

print()

print("\n", programs[12], sep="")
print(flows[0])
print(classes[535])
print(teachers[0])
print(classes[406])