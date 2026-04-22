import os
import datetime
import time
from enum import Enum
import GPUtil
"""
Simply prints text with two additional features:
- show timestamp and log level each time
- can be muted
"""

class LogLevel(Enum):
    INFO = 1
    WARNING = 2
    ERROR = 3

class Logger():
    def __init__(self, save_path=None, muted=False):
        self.time0 = None
        self.muted = muted
        self.save_path = save_path
        if save_path is not None and os.path.exists(save_path):
            os.remove(save_path)
        self.print('PyTorch implementation of "Variational auto-encoder for collagen fiber centerline generation and extraction in fibrotic cancer tissues"')

    def print(self, msg: str, level=LogLevel.INFO.name):
        timestamp = self._get_timestamp()
        if not self.muted:
            print("{} {} {}".format(timestamp, level, msg)) # print message

        if self.save_path is not None:
            with open(self.save_path, "a+") as log_file:
                log_file.write("{} {} {}\n".format(timestamp, level, msg)) # write message

    def _get_timestamp(self):
        now = datetime.datetime.now()
        timestamp = "{:02}-{:02}-{:02} {:02}:{:02}:{:02}".format(now.year, now.month, now.day, now.hour, now.minute, now.second)
        return timestamp

    def _format_seconds(self, sec):
        m, s = divmod(sec, 60)
        h, m = divmod(m, 60)
        return h, m, s

class GPUStat:
    def get_stat(self):
        gpus = [gpu for gpu in GPUtil.getGPUs()]
        stats = []
        for gpu in gpus:
            s = {}
            s['name'] = gpu.name
            s['id'] = gpu.id
            s['mem_total'] = gpu.memoryTotal
            s['mem_free'] = gpu.memoryFree # MB
            s['mem_used'] = gpu.memoryUsed
            s['mem_util'] = gpu.memoryUtil * 100 # %
            s['temperature'] = gpu.temperature # C
            stats.append(s)
        return stats

    def get_stat_str(self):
        gpus = [gpu for gpu in GPUtil.getGPUs()]
        stat_strs = []
        for gpu in gpus:
            s = "  [{}] {}, Memory: total({:,.1f} GB) used({:,.1f} GB) free({:,.1f} GB) {:,.0f}% | temperature({:.0f} 'C)".format(gpu.id, gpu.name, gpu.memoryTotal/1000.0, gpu.memoryUsed/1000.0, gpu.memoryFree/1000.0, gpu.memoryUtil*100, gpu.temperature)
            stat_strs.append(s)
        return '\n'.join(stat_strs)