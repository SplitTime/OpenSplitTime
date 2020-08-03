with sub_splits as
         (select distinct on (split_id, sub_split_bitkey) course_id, split_id, sub_split_bitkey, distance_from_start
          from split_times
                   join splits on splits.id = split_times.split_id),

     sub_split_segments as
         (select ss1.course_id,
                 ss1.split_id            as begin_split_id,
                 ss1.sub_split_bitkey    as begin_bitkey,
                 ss1.distance_from_start as begin_distance,
                 ss2.split_id            as end_split_id,
                 ss2.sub_split_bitkey    as end_bitkey,
                 ss2.distance_from_start as end_distance
          from sub_splits ss1
                   cross join sub_splits ss2
          where ss1.course_id = ss2.course_id
            and ((ss1.distance_from_start = ss2.distance_from_start and ss1.sub_split_bitkey < ss2.sub_split_bitkey)
              or (ss1.distance_from_start < ss2.distance_from_start)))

select course_id,
       begin_split_id,
       begin_bitkey,
       end_split_id,
       end_bitkey,
       bst.effort_id,
       bst.lap,
       bst.absolute_time                         as begin_time,
       est.absolute_time                         as end_time,
       est.elapsed_seconds - bst.elapsed_seconds as elapsed_seconds,
       case
           when bst.data_status is null or est.data_status is null
               then null
           when bst.data_status < est.data_status
               then bst.data_status
           else est.data_status
           end                                   as data_status
from sub_split_segments sss
         join split_times bst on bst.split_id = begin_split_id and bst.sub_split_bitkey = begin_bitkey
         join split_times est on est.split_id = end_split_id and est.sub_split_bitkey = end_bitkey and
                                 est.effort_id = bst.effort_id and est.lap = bst.lap
order by course_id, begin_distance, begin_bitkey, end_distance, end_bitkey, lap, effort_id
