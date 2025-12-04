vim.g.mapleader = " "
vim.keymap.set('n', '<leader>ff', vim.cmd.Ex)
vim.keymap.set('n', '<leader>ya', 'mjggVG"+y\'j')


vim.keymap.set('n', 'm', 'h')
vim.keymap.set('n', 'h', 'm')

vim.keymap.set('n', 'n', 'j')
vim.keymap.set('n', 'j', 'n')

vim.keymap.set('n', 'e', 'k')
vim.keymap.set('n', 'k', 'e')

vim.keymap.set('n', 'l', 'u')
vim.keymap.set('n', 'i', 'l')
vim.keymap.set('n', 'u', 'i')

vim.keymap.set('v', 'm', 'h')
vim.keymap.set('v', 'h', 'm')

vim.keymap.set('v', 'n', 'j')
vim.keymap.set('v', 'j', 'n')

vim.keymap.set('v', 'e', 'k')
vim.keymap.set('v', 'k', 'e')

vim.keymap.set('v', 'l', 'u')
vim.keymap.set('v', 'i', 'l')
vim.keymap.set('v', 'u', 'i')

--  vim.keymap.set('n', '<leader>e', ':lua vim.lsp.buf.hover()');

vim.keymap.set('n', '<leader>pp', '"+p')
vim.keymap.set('v', '<leader>yy', '"+y')

vim.keymap.set("v", "N", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "E", ":m '<-2<CR>gv=gv")
