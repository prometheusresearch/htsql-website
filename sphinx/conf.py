
from conf import *

templates_path = ['templates']
html_static_path = ['static']
extensions.append('sphinxcontrib.htrafdemo')
extensions.append('blog')

build_website = True

html_theme = 'basic'
html_style = 'common.css'
html_title = project
html_sidebars = { '**': ['sidebar.html'] }
html_show_copyright = False
html_show_sphinx = False
diagram_texinputs = ['doc/dia']
disqus_shortname = 'htsql'
disqus_developer = False

