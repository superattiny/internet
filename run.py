import webview
import os

# CRM faylining joyi
html_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'CRM_Tizimi.html')

webview.create_window(
    title    = "TV Ta'mirlash CRM",
    url      = 'file:///' + html_path.replace('\\', '/'),
    width    = 1400,
    height   = 900,
    min_size = (1024, 700),
    resizable= True
)

webview.start()
