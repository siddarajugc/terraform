#!/usr/bin/python3
from argparse import ArgumentParser

import os
from datetime import datetime, timedelta

from collections import OrderedDict
import logging

from es_publisher import SampleCollector

logging.basicConfig(format='%(asctime)s: %(message)s', level=logging.INFO)

LAST_UUID = 'LAST_UUID'
DATA_DIR = os.environ.get('DATA_DIR')
if DATA_DIR is None or DATA_DIR == "":
    DATA_DIR = '/home/perf/gartner/avail_data/'

ES_URI = os.environ.get('ES_URI')
if ES_URI is None or ES_URI == "":
    ES_URI = 'http://localhost:9201'
ES_INDEX = os.environ.get('ES_INDEX')
if ES_INDEX is None or ES_INDEX == "":
    ES_INDEX = 'gartner'
ES_TYPE = os.environ.get('ES_TYPE')
if ES_TYPE is None or ES_TYPE == "":
    ES_TYPE = 'cpu_test'

# exit codes
EXIT_TEST_COMPLETED = 0
EXIT_TEST_FAILED = 10
EXIT_ES_UPLOAD_FAILED = 7
DASH = '-'


def write_file(filename, data):
    if not os.path.exists(os.path.dirname(filename)):  # this should exist already
        os.makedirs(os.path.dirname(filename))
    with open(filename, "w") as dfile:
        dfile.write(str(data))


def read_file(filename):
    if os.path.exists(filename):
        with open(filename, 'r') as dfile:
            content = dfile.read()
        return content
    return None


def get_base_name(filename):
    base = os.path.basename(filename)
    return os.path.splitext(base)[0]


def is_csv_file(filename):
    return True if filename.endswith('.csv') else False


def upload_data(samples):
    for s in samples:
        # process one sample at a time so we can cantrol better if any doc fails
        try:
            collector = SampleCollector(ES_URI, ES_INDEX, ES_TYPE)
            collector.AddSamples([s])  # pass in as a list
            collector.PublishSamples()
        except Exception as ex:
            logging.info('Failed to upload sample: %s, error: %s', s, ex)
            pass


#       os._exit(EXIT_ES_UPLOAD_FAILED)


def get_args():
    parser = ArgumentParser()
    parser.add_argument('-m', '--mzone', help='mzr, e.g. wdc_g5_prod_mzr')
    parser.add_argument('-r', '--region', help='region name, e.g. us-south')
    parser.add_argument('-t', '--testname', help='testname, e.g. cpu')
    parser.add_argument('-p', '--profile', help='profile, e.g. cx2-2x4')
    parser.add_argument('-s', '--schedule', type=int, default=10, help='schedule time, e.g. 5 or 10 (min)')
    return parser.parse_args()


NUM_ZONES = 3


def init_test_sample(region, ordinal):
    sample = {}
    sample['tot_successes'] = 0
    sample['tot_fails'] = ordinal  # init to all fail
    num_vms = ordinal // NUM_ZONES
    for index in range(1, NUM_ZONES + 1):
        zone = region + '-' + str(index)
        sample[zone] = {}
        sample[zone]['successes'] = 0
        sample[zone]['fails'] = num_vms  # init to all fail
        sample[zone]['vms'] = []
        zone = 'zone' + str(index)  # duplicate with different name
        sample[zone] = {}
        sample[zone]['successes'] = 0
        sample[zone]['fails'] = num_vms  # init to all fail
        sample[zone]['vms'] = []
    return sample


def check_elapsed_time(schedule, sample):
    '''
  schedule: minutes
  Given a sample, calculate total elapsed time
  1.. test_starttime: provision epoch start time
  2.. test_endtime: terminate epoch start time + elapsed time
  3..
    endtimes = []
    for each vm:
        endtimes.append(starttime + elapsed time)

    last_test_endtime = max(endtimes)
    if last_test_endtime > test_endtime:
        test_endtime = last_test_endtime

    total_elapsed_time = test_endtime - test_starttime
    if total_elapsed_time > 300:
        # failure

    -- set this in the doc
    sample['test_starttime'] = same as provision start time
    sample['test_endtime'] = test_endtime
    sample['total_elapsed_time'] = sample['test_endtime'] - sample['test_starttime']
    sample['elapsed_time_fail'] = 0 # if < 5 min else 1
  =>
  Add an extra query, 9th bar that turns red when this happens
  So we can tell difference between > 5 or parts failing
  '''
    test_starttime = sample['provision']['starttime']
    test_endtime = sample['terminate']['starttime'] + sample['terminate']['elapsedtime']

    endtimes = []
    for zone in ['zone1', 'zone2', 'zone3']:
        for num in range(0, len(sample['testdata'][zone]['vms'])):
            if 'starttime' in sample['testdata'][zone]['vms'][num]:
                endtimes.append(
                    sample['testdata'][zone]['vms'][num]['starttime'] + sample['testdata'][zone]['vms'][num][
                        'elapsedtime'])

    last_test_endtime = max(endtimes) if len(endtimes) > 0 else 0
    if last_test_endtime > test_endtime:
        test_endtime = last_test_endtime

    total_elapsed_time = test_endtime - test_starttime if test_endtime > test_starttime else 0  # this is a failure with no terminate data
    sample['test_starttime'] = test_starttime
    sample['test_endtime'] = test_endtime
    sample['total_elapsed_time'] = total_elapsed_time
    logging.info('Total test elapsed time: %s secs', total_elapsed_time)
    if total_elapsed_time > schedule * 60 or total_elapsed_time <= 0:
        sample['elapsed_time_fail'] = 1  # test exceeded the schedule or no terminate data
        logging.info('This testrun exceeded the given schedule or there was no terminate data')


def process_test_data(region, data_path, uuid, ordinal):
    sample = init_test_sample(region, ordinal)

    if not os.path.exists(data_path):
        # this is a rare case that should not occur but should it happen, just create the data_path dir
        os.makedirs(data_path, exist_ok=True)

    for f in os.listdir(data_path):
        base_names = get_base_name(f).split('-')  # 1607273342-us-east-1-160430
        file_uuid = base_names[0]
        if file_uuid == uuid:
            zone = region + '-' + base_names[3]  # us-south-1, TODO: remove this later
            zone_dupe = 'zone' + base_names[3]  # zone1
            logging.info('found new test data file, base name: %s, uuid: %s, zone: %s', f, uuid, zone)
            file_path = os.path.join(data_path, f)
            test_data = read_file(file_path)
            logging.info('test_data: %s', test_data)
            # $region,$service,$sku,$test_date,$test_data,$group,$ordinal,$starttime,$elapsedtime,$return_value,$uuid,$annotation
            # us-east,cpu,cx2-2x4,2020-12-06 17:32:21Z,data,1,6,1607275941,10,0,1607275862,
            data_items = test_data.split(',')
            data_sample = {}
            data_sample['test_date'] = data_items[3]
            data_sample['starttime'] = int(data_items[7])
            data_sample['elapsedtime'] = int(data_items[8])
            data_sample['return_value'] = int(data_items[9])
            data_sample['success'] = 0  # for charting, init
            data_sample['fail'] = 1  # for charting, init
            if len(data_items) > 10 and data_items[9] != '' and int(data_items[9]) == 0:
                data_sample['success'] = 1  # for charting
                data_sample['fail'] = 0  # for charting

            sample[zone]['vms'].append(data_sample)
            sample[zone]['successes'] += data_sample['success']  # total for the zone, for charting
            sample[zone]['fails'] -= data_sample['success']  # should come down to 0 if all success
            # duplicate with diffeent name
            sample[zone_dupe]['vms'].append(data_sample)
            sample[zone_dupe]['successes'] += data_sample['success']  # total for the zone, for charting
            sample[zone_dupe]['fails'] -= data_sample['success']  # should come down to 0 if all success
            sample['tot_successes'] += data_sample['success']  # total for the testrun, for charting
            sample['tot_fails'] -= data_sample['success']  # should come down to 0 if all success

    return sample


def process_files(args, provision_path, terminate_path, data_path, last_uuid, current_uuid):
    logging.info('Processing files')
    exit_code = EXIT_TEST_COMPLETED
    samples = []
    last_uuid_to_save = last_uuid
    if os.path.exists(provision_path):
        for f in os.listdir(provision_path):
            if is_csv_file(f):
                file_uuid = get_base_name(f)
                logging.info('file_uuid to check: %s', file_uuid)
                if last_uuid is None or (file_uuid > last_uuid and file_uuid < current_uuid):
                    file_path = os.path.join(provision_path, f)
                    # all files should be plain files
                    logging.info('new file found: %s', file_path)
                    data = read_file(file_path)
                    logging.info('provision data: %s', data)
                    data_items = data.split(',')

                    # $region,$service,$sku,$test_date,$test_provision,$group,$ordinal,$starttime,$elapsedtime,$return_value,$uuid,$annotation
                    # us-east,cpu,cx2-2x4,2020-12-06 16:49:02Z,control-provision,1,6,1607273342,56,0,1607273342,
                    sample = OrderedDict()  # basic metrics for one test run
                    sample['metric'] = data_items[1]  # cpu
                    sample['mzone'] = args.mzone  # wdc_g5_prod_mzr, add this to conform to the rest of benchmark data
                    sample['region'] = args.region  # us-east
                    sample['region_'] = args.region.replace(DASH, '_')  # same as region but us-east -> us_east
                    sample['profile'] = data_items[2]  #
                    sample['test_date'] = data_items[3]  #
                    sample['group'] = int(data_items[5])
                    sample['ordinal'] = int(data_items[6])
                    sample['uuid'] = file_uuid  # should be same as data[10]
                    sample['jenkins_build'] = os.environ.get(
                        'BUILD_NUMBER')  # BUILD_ID and BUILD_NUMBER return same number
                    sample['jenkins_build_url'] = os.environ.get('BUILD_URL')

                    # use same timestamp as the actual first provision test started,
                    # this should be unique so we don't upload duplicates
                    sample['timestamp'] = int(
                        data_items[7])  # use same timestamp as the actual first provision test started,

                    # these are used to calculate total test runtime
                    sample['test_starttime'] = int(data_items[7])  # init
                    sample['test_endtime'] = int(data_items[7])  # init
                    sample['total_elapsed_time'] = 0  # init
                    sample['elapsed_time_fail'] = 0  # init

                    # instead of generating uuid, to avoid duplicates when reloading data in case of problems, use below as unique id
                    # any docs matching this id, will be updated instead of a duplicated doc
                    sample['sample_uri'] = sample['metric'] + DASH + sample['region'] + DASH + sample[
                        'profile'] + DASH + \
                                           str(sample['group']) + DASH + str(sample['ordinal']) + DASH + sample['uuid']

                    # provisioning data
                    data_sample = {}
                    data_sample['starttime'] = int(data_items[7])
                    data_sample['elapsedtime'] = int(data_items[8])
                    data_sample['return_value'] = int(data_items[9])
                    data_sample['success'] = 0  # init to fail
                    data_sample['fail'] = 1
                    if len(data_items) > 10 and data_items[9] != '' and int(data_items[9]) == 0:
                        data_sample['success'] = 1  # for charting
                        data_sample['fail'] = 0  # for charting
                    if data_sample['fail'] > 0:
                        exit_code = EXIT_TEST_FAILED
                    sample['provision'] = data_sample  # just using short name for chart queries

                    # test data from vms
                    sample['testdata'] = process_test_data(args.region, data_path, file_uuid,
                                                           sample['ordinal'])  # pass in ordinal
                    if sample['testdata']['tot_fails'] > 0:
                        exit_code = EXIT_TEST_FAILED

                    # init to fail first, also init here so we always have something even when the file is not found
                    terminate_sample = {}
                    terminate_sample['success'] = 0
                    terminate_sample['fail'] = 1
                    terminate_sample['starttime'] = 0
                    terminate_sample['elapsedtime'] = 0
                    terminate_sample['return_value'] = 1

                    # terminate data
                    file_path = os.path.join(terminate_path, f)
                    logging.info('terminate file to read: %s', file_path)
                    if os.path.exists(file_path):
                        data = read_file(file_path)
                        logging.info('terminate data: %s', data)
                        data_items = data.split(',')
                        # $region,$service,$sku,$test_date,$test_terminate,$group,$ordinal,$starttime,$elapsedtime,$return_value,$uuid,$annotation
                        # us-east,cpu,cx2-2x4,2020-12-06 17:35:01Z,control-terminate,1,6,1607276101,55,0,1607275862,
                        terminate_sample['starttime'] = int(data_items[7])
                        terminate_sample['elapsedtime'] = int(data_items[8])
                        terminate_sample['return_value'] = int(data_items[9])
                        if len(data_items) > 10 and data_items[9] != '' and int(data_items[9]) == 0:
                            terminate_sample['success'] = 1  # for charting
                            terminate_sample['fail'] = 0  # for charting
                    else:
                        logging.info('could not find terminate file, assuming failed')
                    if terminate_sample['fail'] > 0:
                        exit_code = EXIT_TEST_FAILED
                    sample['terminate'] = terminate_sample

                    check_elapsed_time(args.schedule, sample)
                    samples.append(sample)
                    last_uuid_to_save = file_uuid

    return samples, last_uuid_to_save, exit_code


def main():
    args = get_args()
    schedule = args.schedule * 60  # secs, defaults to 600
    ten_minutes = timedelta(seconds=schedule)
    now = datetime.utcnow() - ten_minutes  # ten min back, in utc
    year = now.year
    month = f"{now:%m}"
    day = f"{now:%d}"
    data_path = DATA_DIR + args.region + os.path.sep + args.testname + os.path.sep + args.profile + os.path.sep + str(
        year) + os.path.sep + str(month) + os.path.sep + str(day)
    logging.info('utcnow: %s, data_path: %s', now, data_path)

    #   current_uuid = str(now.timestamp() - SCHEDULED_RUNTIME).split('.')[0]  # uuid in utc
    #   logging.info('current_uuid(utc): %s', current_uuid)

    # for the current uuid, get start time of the next interval
    currtime = datetime.now().timestamp()
    currtime = (currtime - currtime % schedule) + schedule
    current_uuid = str(currtime).split('.')[0]
    logging.info('current_uuid: %s', current_uuid)

    last_uuid_file = DATA_DIR + args.region + os.path.sep + args.testname + os.path.sep + args.profile + os.path.sep + LAST_UUID
    last_uuid = read_file(last_uuid_file)
    logging.info('last uuid: %s', last_uuid)

    control_provision_path = data_path + os.path.sep + 'control-provision'
    control_terminate_path = data_path + os.path.sep + 'control-terminate'
    data_path = data_path + os.path.sep + 'data'
    logging.info('control_provision_path: %s', control_provision_path)
    logging.info('control_terminate_path: %s', control_terminate_path)
    logging.info('data_path: %s', data_path)

    samples, last_uuid, exit_code = process_files(args, control_provision_path, control_terminate_path, data_path,
                                                  last_uuid, current_uuid)
    logging.info('samples: %s', samples)

    if samples:
        upload_data(samples)
        logging.info('samples uploaded')
        write_file(last_uuid_file, last_uuid)
        logging.info('last_uuid processed: %s', last_uuid)

    logging.info('DONE')
    os._exit(exit_code)


if __name__ == '__main__':
    main()
