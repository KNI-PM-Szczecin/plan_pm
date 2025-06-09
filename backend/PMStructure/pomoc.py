zmienna = "Programowanie N mgr 1.50 2023/2024 zima"

zmienna = zmienna.split()

print(zmienna)
trybIndex = 0
try:
    trybIndex = zmienna.index("mgr")
except ValueError:
    trybIndex = zmienna.index("inż.")
    
rok = zmienna[trybIndex + 1]
trybStudiow = zmienna[trybIndex]
print(trybStudiow)
print(float(rok).__floor__())