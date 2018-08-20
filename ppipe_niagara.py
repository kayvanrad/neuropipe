#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu May  3 13:48:29 2018

@author: aras
"""

def printhelp():
    p=subprocess.Popen(['pipe.py','-h'])
    p.communicate()
    print('---------------------------------')
    print('Additional job scheduler options:')
    print('--mem <amount in GB = 32>')

import workflow
import preprocessingstep
import sys, getopt, os
import subprocess

subjectsfiles=[]
combs=[]
addsteps=False
runpipesteps=[] # this is a list
optimalpipesteps=[] # this is a list of lists
fixedpipesteps=[] # this is a list
showpipes=False
resout=''
parcellate=False
meants=False
seedconn=False
tomni=False
runpipename=''
optpipename='opt'
fixpipename='fix'
outputsubjectsfile=''
keepintermed=False
runpipe=False

envvars=workflow.EnvVars()

# the getopt libraray somehow "guesses" the arguments- for example if given
# '--subject' it will automatically produce '--subjects'. This can cause problems
# later when arguments from sys.argv are passed to pipe.py. The following checks
# in advance to avoid such problems
pipe_args = sys.argv[1:]
for arg in pipe_args:
    if '--' in arg:
        if not arg in ['--help','--pipeline', '--subjects', '--perm', '--onoff',\
                       '--permonoff', '--const', '--select', '--add',\
                       '--combine', '--fixed', '--showpipes', '--template',\
                       '--resout', '--parcellate', '--meants', '--seedconn',\
                       '--tomni', '--boldregdof', '--structregdof',\
                       '--boldregcost', '--structregcost', '--outputsubjects',\
                       '--keepintermed', '--runpipename', '--fixpipename',\
                       '--optpipename','--mem']:
            printhelp()
            sys.exit()


runpipefile=''
subjfile=''
mem='32'

# parse command-line arguments
try:
    (opts,args) = getopt.getopt(sys.argv[1:],'h',\
                                ['help','pipeline=', 'subjects=', 'perm=', 'onoff=', 'permonoff=', 'const=', 'select=', 'add', 'combine', 'fixed=', 'showpipes', 'template=', 'resout=', 'parcellate', 'meants', 'seedconn', 'tomni', 'boldregdof=', 'structregdof=', 'boldregcost=', 'structregcost=', 'outputsubjects=', 'keepintermed', 'runpipename=', 'fixpipename=', 'optpipename=','mem='])
except getopt.GetoptError:
    printhelp()
    sys.exit()
for (opt,arg) in opts:
    if opt in ('-h', '--help'):
        printhelp()
        sys.exit()
    elif opt in ('--pipeline'):
        runpipesteps+=preprocessingstep.makesteps(arg)
        runpipe=True
        (directory,runpipefile)=os.path.split(arg)
        #(directory,namebase)=os.path.split(arg)
        #namebase=fileutils.removext(namebase)
        #runpipename+=namebase
    elif opt in ('--fixed'):
        fixedpipesteps+=preprocessingstep.makesteps(arg)
    elif opt in ('--perm'):
        steps=preprocessingstep.makesteps(arg)
        if addsteps:
            optimalpipesteps+=list(preprocessingstep.permutations(steps))
        else:
            optimalpipesteps=list(preprocessingstep.concatstepslists(optimalpipesteps,\
                                                                     list(preprocessingstep.permutations(steps))))
    elif opt in ('--onoff'):
        steps=preprocessingstep.makesteps(arg)
        if addsteps:
            optimalpipesteps+=list(preprocessingstep.onoff(steps))
        else:
            optimalpipesteps=list(preprocessingstep.concatstepslists(optimalpipesteps,\
                                                                     list(preprocessingstep.onoff(steps))))

    elif opt in ('--permonoff'):
        steps=preprocessingstep.makesteps(arg)
        if addsteps:
            optimalpipesteps+=list(preprocessingstep.permonoff(steps))
        else:
            optimalpipesteps=list(preprocessingstep.concatstepslists(optimalpipesteps,\
                                                                     list(preprocessingstep.permonoff(steps))))

    elif opt in ('--select'):
        steps=preprocessingstep.makesteps(arg)
        if addsteps:
            optimalpipesteps+=list(preprocessingstep.select(steps))
        else:
            optimalpipesteps=list(preprocessingstep.concatstepslists(optimalpipesteps,\
                                                                     list(preprocessingstep.select(steps))))

    elif opt in ('--const'):
        steps=preprocessingstep.makesteps(arg)
        if addsteps:
            optimalpipesteps+=[steps]
        else:
            optimalpipesteps=list(preprocessingstep.concatstepslists(optimalpipesteps,[steps]))
    elif opt in ('--subjects'):
        subjectsfiles.append(arg)
        (directory,subjfile)=os.path.split(arg) # this is inconsistent with the idea of having multiple subject files- maybe just get one subjects file?
    elif opt in ('--mem'):
        mem=arg

if subjectsfiles==[]:
    print('Please specify subjects file. Get help using -h or --help.')


base_command = 'pipe.py'

if runpipe:

    subjects=[]
    count=0

    for sfile in subjectsfiles:
        subjects=workflow.getsubjects(sfile)

        for s in subjects:
            # first create individual subjects files and job bash scripts to be
            # submitted to the job manager
            count+=1
            subject_fname = '.temp_subj_'+subjfile+'_'+runpipefile+str(count)+'.txt'
            qbatch_fname = '.temp_job_'+subjfile+'_'+runpipefile+str(count)+'.sh'
            qbatch_file = open(qbatch_fname, 'w')
            
            workflow.savesubjects(subject_fname,[s],append=False)
            
            # write the header stuff
            qbatch_file.write('#!/bin/bash\n\n')
            qbatch_file.write('#SBATCH --nodes=1\n')
            qbatch_file.write('#SBATCH --time=12:00:00\n')
            qbatch_file.write('#SBATCH --output=.temp_job_'+subjfile+'_'+runpipefile+str(count)+'.o'+'\n')
                              
            qbatch_file.write(base_command + ' ')
            #Just re-use the arguments given here
            pipe_args = sys.argv[1:]
            pipe_args[pipe_args.index('--subjects')+1] = subject_fname
            if '--mem' in pipe_args:
                del pipe_args[pipe_args.index('--mem')+1]
                del pipe_args[pipe_args.index('--mem')]
            command_str  = ' '.join(pipe_args)
            qbatch_file.write(command_str)
            qbatch_file.write('\n')
            
            qbatch_file.close()
            
            # now submit job
            p=subprocess.Popen(['sbatch',qbatch_fname])
            p.communicate()            

