#!/usr/bin/env python
from jinja2 import Environment, FileSystemLoader

template_env = Environment(loader=FileSystemLoader("."))
# TMPL_FNAME = "Tags.xml.tmpl.better"
# OUT_FNAME = "Tags.xml"
TMPL_FNAME = "ShieldSharing.xml.tmpl"
OUT_FNAME = "ShieldSharing.xml"

with open(OUT_FNAME, 'w') as f:
    f.write(template_env.get_template(TMPL_FNAME).render())
