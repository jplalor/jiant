import argparse 
import csv 
import os 


def main():
    parser = argparse.ArgumentParser() 
    parser.add_argument('-d', '--dir', help='location of files') 
    args = parser.parse_args() 

    task_names = [
        'cola',
        'mnli',
        'mrpc',
        'qnli',
        'qqp',
        'rte',
        'sst',
        'wnli'
    ]

    # list the directories we'll loop through
    dirs = os.listdir(args.dir) 
    dirs = [d for d in dirs if 'artcrowd' in d] 

    for task in task_names:
        rp_fname = '{}/rps/{}.rp'.format(args.dir, task) 
        with open(rp_fname, 'w') as outfile:
            outwriter = csv.writer(outfile, delimiter='\t')
            for d in dirs:
                mid = 'm-{}'.format(d[-4:])
                task_fname = '{}/{}/{}_train.tsv'.format(args.dir, d, task) 
                with open(task_fname, 'r') as infile:
                    inreader = csv.reader(infile, delimiter='\t') 
                    next(inreader) 
                    for row in inreader:
                        idx, pred, s1, s2, true_label = row 
                        if task in ['rte', 'qnli']:
                            if pred == 'entailment':
                                pred = 1
                            else:
                                pred = 0
                        if pred == true_label:
                            response = 1
                        else:
                            response = 0
                        outrow = [mid, idx, response] 
                        outwriter.writerow(outrow) 
            




if __name__ == '__main__':
    main() 

