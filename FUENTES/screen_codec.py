from collections import defaultdict
def pack(a):
 d=defaultdict(list);o=bytearray();lit=bytearray();i=0
 def flush():
  if lit:o.append(len(lit));o.extend(lit);lit.clear()
 while i<len(a):
  best=0;off=0
  if i+3<=len(a):
   for j in reversed(d[a[i:i+3]]):
    k=3
    while k<min(255,len(a)-i) and a[j+k]==a[i+k]:k+=1
    if k>best:best=k;off=i-j
    if k==255:break
  if best>=3 and off<=2047 and best<=18 and (((best-3)<<3)|(off>>8))!=127:
   n=best;flush();o.extend([128|((n-3)<<3)|(off>>8),off&255])
  elif best>=5:
   n=best;flush();o.extend([255,n,off&255,off>>8])
  elif best>=3 and off<=2047:
   n=best;flush();o.extend([128|((n-3)<<3)|(off>>8),off&255])
  else:
   n=1;lit.append(a[i]);
   if len(lit)==127:flush()
  for j in range(i,i+n):d[a[j:j+3]].append(j)
  i+=n
 flush();o.append(0);return bytes(o)
