.PHONY: help repl

default: help

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  help            to see this message"
	@echo "  demo/plugin.lua to create the plugin demo"

demo/plugin.lua: multiplotlines.lua demo/in/plugin.lua
	cat multiplotlines.lua demo/in/plugin.lua > demo/plugin.lua
