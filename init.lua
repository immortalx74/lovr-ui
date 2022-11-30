local root = (...):gsub('/', '.'):gsub('%.init$', '')
return require(root .. '.ui.ui')
