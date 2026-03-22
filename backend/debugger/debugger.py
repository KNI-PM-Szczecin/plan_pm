from dataclasses import dataclass, field
from datetime import datetime
from json import loads as loadJSON, dumps as dumpJSON

def tstamp(val):
    return datetime.fromtimestamp(val).strftime('%Y-%m-%d %H:%M')

def printClass(i):
    print(f"{i['program']} - \r\t\t\t\t\t\t\t\t{i['group']}")
    # print(f"\t{i['subject']}:")
    # print(f"\t{i['startTime']}")

@dataclass
class ScheduleData:
    programs: list
    classes: list
    teachers: list
    subjects: list
    rooms: list
    buildings: list

def readJson(input):
    with open(input, "r", encoding="utf-8") as file:
        return loadJSON(file.read())
    
def normalize(JSON):
    return ScheduleData(
        programs=           JSON.get("programs", []),
        classes=            JSON.get("classes", []),
        teachers=           JSON.get("teachers", []),
        subjects=           JSON.get("subjects", []),
        rooms=              JSON.get("rooms", []),
        buildings=          JSON.get("buildings", []),
        teachersclasses=    JSON.get("teachersclasses", [])
    )

def has_multiple_unique_programs(class_list):
    programs = {item["program"] for item in class_list}
    return len(programs) > 1

def findOutliers(key, data):
    findings = {}

    for i in norm.classes:
        i["program"] = f"{norm.programs[i["program"]]["name"]} -{i["program"]}"
        i["subject"] = norm.subjects[i["subject"]]
        i["startTime"] = f"{tstamp(i["startTime"])[5:]} - {i["subject"]} - {i['room']}"
        i["endTime"] = tstamp(i["endTime"])[5:]
        if not i[key] == data:
            if i['startTime'] not in findings:
                findings[i['startTime']] = []
            findings[i['startTime']].append(i)

    findings = sorted(findings.items(), key=lambda x: x[0])

    for i in findings:
        if has_multiple_unique_programs(i[1]):
            print(f"\n{i[0]}:")
            for x in i[1]:
                printClass(x)


key = "subject"
data = "Wychowanie fizyczne"

print(f"\nStarting parser debugger searching for: {data} in {key}")
JSON = readJson("../output/parser.json")
norm = normalize(JSON)

findOutliers(key, data)