-- Run a command using the OS shell and capture the stdout
-- Strips exactly one trailing newline if present, does not strip any other whitespace.
-- Asserts that the command exits cleanly
local function capture(command)
	local p = io.popen(command)
	local output = p:read("*a")
	assert(p:close())
	-- Strip exactly one trailing newline from the output, if there is one
	return output:match("(.-)\n$") or output
end

local old = {}
for p in capture("ls " .. arg[1]):gmatch("[^\n]+") do
	table.insert(old, p)
end

local new = {}
for p in capture("ls " .. arg[2]):gmatch("[^\n]+") do
	table.insert(new, p)
end

for i = 1, #old do
	assert(old[i]:match("[^.]+") == new[i]:match("[^.]+"))

	if not old[i]:match("FreeBSD%-.*") then
		goto continue
	end

	local before = capture("pkg info -b -F " .. arg[1] .. "/" .. old[i])
	local after = capture("pkg info -b -F " .. arg[2] .. "/" .. new[i])


	local shlibs_after = {}
	for shlib in after:match("[^\n]+(.*)"):gmatch("[^\n]+") do
		shlibs_after[shlib] = true
	end

	local shlibs_lost = {}
	for shlib in before:match("[^\n]+(.*)"):gmatch("[^\n]+") do
		if not shlibs_after[shlib] then
			table.insert(shlibs_lost, shlib)
		end
	end

	if #shlibs_lost > 0 then
		print(before:match("[^.]+") .. " no longer provides:")
		for _, shlib in ipairs(shlibs_lost) do
			print(shlib)
		end
		print()
	end
	::continue::
end
