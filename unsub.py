# Ouvre les pages de desinscription des messsage

from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import re
import time

# Ouvre Firefox
driver = webdriver.Firefox()
driver.get("https://zimbra.free.fr/zimbra/mail")
time.sleep(2)
# Remplit id et mdp
element = driver.find_element_by_name("login")
element.send_keys("martin.ecarnot")
element = driver.find_element_by_name("password")
element.send_keys("hifh5iccm")
element = driver.find_elements_by_xpath("//input[@type='submit' and @value='connexion']")[0]
element.click()
time.sleep(2)

# Clique dans le repertoire "Se desinscrire"
element = driver.find_element_by_id('zti__main_Mail__188012_textCell')
element.click()

# Liste tous les elements
ids = driver.find_elements_by_xpath('//*[@id]')
# Selectionne ceux qui ont l'attribut 'id'
l = []
for ii in range(1000):
    l.append(ids[ii].get_attribute('id'))
# Selectionne ceux qui commencent par 'zli__CLV__-'
res = [k for k in l if 'zli__CLV__-' in k]

# Boucle sur n messages
for i in range(len(res)):
    print(i)
    # Clique sur un message
    el1 = driver.find_element_by_id(res[i])
    el1.click()
    # On se place dans le iframe du texte
    driver.switch_to.frame(driver.find_element_by_id("zv__CLV__MSG_body__iframe"))
    # Lit le code source du iframe
    src = driver.page_source
    # Recherche le texte 'sabonn' ou 'sinscrire', ou 'unsubscribe'
    text_found = re.search(r'sabonn', src)
    if not text_found:
        text_found = re.search(r'sinscri', src)
    if not text_found:
        text_found = re.search(r'unsubscribe', src)
    if not text_found:
        text_found = re.search(r'retiré de', src)
    if text_found:
        # Cherche les liens web (par "href")
        href=[href.start() for href in re.finditer('href', src)]
        # Trouve le href le plus proche du texte de desabonnement
        closest_href=min(href, key=lambda x:abs(x-text_found.span()[1]))
        # Extrait le lien correspondant
        src_fin=src[closest_href+6:]
        guil=[guil.start() for guil in re.finditer('"', src_fin)]
        link=src_fin[0:guil[0]]

        if 'http' in link:
            # Ouvre un nouvel onglet et y ouvre le lien
            driver.execute_script("window.open();")
            hdl=driver.window_handles
            driver.switch_to.window(hdl[1])
            try:
                driver.get(link)
            except:
                print("An exception occurred")
            # Retourne a la page principale
            driver.switch_to.window(hdl[0])

    driver.switch_to.parent_frame()


driver.close()



    try:
        1+1#driver.get(link)
    except:
        print("An exception occurred")
