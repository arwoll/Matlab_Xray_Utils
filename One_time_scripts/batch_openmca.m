dead_struct.key = 'SD119E4_1200Ag_50';
specfile = 'SD106a';
for k=7
    s = openmca(specfile, 'scan', k, 'dead', dead_struct);
end