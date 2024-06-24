t = open("input.txt", "r")
t2 = open("output.txt", "w")
s = str(t.readlines())
s2 = s.split("X\"");

def bina(text):
  i = int(text, 16)
  out = ""
  for j in range(1,17):
    out += str((1 << (16 - j) & i)>>(16 - j))
  return out

for i in range(512 + 1, 1 + 767):
  text = str(s2[i].replace("\n","").split("\"")[0])
  hex = bina(text)
  t2.write(hex + " " + text + "\n")