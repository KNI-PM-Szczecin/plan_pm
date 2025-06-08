gowno = "Programowanie N mgr 1.50 2023/2024 zima"

gowno = gowno.split()

print(gowno)
trybIndex = 0
try:
    trybIndex = gowno.index("mgr")
except ValueError:
    trybIndex = gowno.index("inż.")
    
rok = gowno[trybIndex + 1]
trybStudiow = gowno[trybIndex]
print(trybStudiow)
print(float(rok).__floor__())