import os
import urllib2

filenames = os.listdir('.')

for filename in filenames:
    if filename.endswith('.url'):
        print filename
        
        with open(filename) as f:
            try:
                url = f.readline()
                response = urllib2.urlopen(url, timeout=10)
                lines = response.readlines()
                
                print '---'
                
                for line in lines:
                    print line
                
                with open(filename[:-4] + '.txt', 'w') as of:
                    for line in lines:
                        of.write(line)
                    
            except:
                pass
                
        print '--------------------------------'
        