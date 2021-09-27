import requests
from bs4 import BeautifulSoup
import os, sys

sys.stdout = open(os.path.join(os.path.split(os.path.realpath(__file__))[0], '..', 'lib', 'educationdata.dart'), 'w+')

def removeSpace(string):
    if (string[0] == ' '):
        return string[1:]
    
    return string

url = "https://splus.cumulus.vub.ac.be/SWS/v3/onevenjr/NL/STUDENTSET/studentset.aspx"
session = requests.Session()
page = session.get(url)
soup = BeautifulSoup(page.content, 'html.parser')

print('final Map<String, Map<String, Map<String, String>>> EducationData = {')
for edutype in soup.find(id='tTypes').find_all('td'):
    data = {"__EVENTTARGET": "tTypeClicked", "__EVENTARGUMENT": edutype.get('id'), "__VIEWSTATE": soup.find(id='__VIEWSTATE') }
    session.post(url, data=data)

    print('\t"' + edutype.text + '": {')

    for fac in soup.find(id='tDepartments').find_all('td'):
        data = {"__EVENTTARGET": "tDepartmentClicked", "__EVENTARGUMENT": fac.get('id'), "__VIEWSTATE": soup.find(id='__VIEWSTATE') }
        facPage = session.post(url, data=data)
        print('\t\t"' + fac.text + '": {')
        facSoup = BeautifulSoup(facPage.content, 'html.parser')
        for el in facSoup.find(id='tTags').find_all('td'): 
            print('\t\t\t"' + removeSpace(el.text) + '" : "' + el.get('id') + '",')
        print("\t\t},")

    print('\t},')

print('};')

sys.stdout.close()