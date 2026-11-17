#ifndef TIMEBASE_H
#define TIMEBASE_H

/* Đổi bộ đếm chu kỳ 27 MHz thành mili giây (không dùng phép chia) */
void     timebase_init(void);
void     resync_clock(void);     /* bỏ qua thời gian vừa vẽ lớn khỏi đồng hồ game */
unsigned timebase_poll(void);    /* số ms trôi qua từ lần gọi trước (tối đa 250) */

#endif
