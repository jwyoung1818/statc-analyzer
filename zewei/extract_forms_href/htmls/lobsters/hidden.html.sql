# Logfile created on 2016-01-05 10:31:30 -0600 by logger.rb/47272
D, [2016-01-05T10:31:30.202030 #2768] DEBUG -- :   [1m[36mUser Load (0.4ms)[0m  [1mSELECT  `users`.* FROM `users`  WHERE `users`.`session_token` = 'yMvDgquEClagp0qkFWmweNDKPFMLfRYlrUmNEDKS9vYY9ks7SltCng7dvAiw'  ORDER BY `users`.`id` ASC LIMIT 1[0m
D, [2016-01-05T10:31:30.206042 #2768] DEBUG -- :   [1m[35mTagFilter Load (0.2ms)[0m  SELECT `tag_filters`.* FROM `tag_filters`  WHERE `tag_filters`.`user_id` = 1
D, [2016-01-05T10:31:30.208982 #2768] DEBUG -- :   [1m[36mStory Load (0.4ms)[0m  [1mSELECT  `stories`.* FROM `stories`  WHERE `stories`.`merged_story_id` IS NULL AND `stories`.`is_expired` = 0 AND `stories`.`id` IN (SELECT `hidden_stories`.`story_id` FROM `hidden_stories`  WHERE `hidden_stories`.`user_id` = 1)  ORDER BY hotness LIMIT 26 OFFSET 0[0m
D, [2016-01-05T10:31:30.209977 #2768] DEBUG -- :   [1m[35mVote Load (0.2ms)[0m  SELECT `votes`.* FROM `votes`  WHERE `votes`.`user_id` = 1 AND 1=0 AND `votes`.`comment_id` IS NULL
D, [2016-01-05T10:31:30.210723 #2768] DEBUG -- :   [1m[36mHiddenStory Load (0.1ms)[0m  [1mSELECT `hidden_stories`.* FROM `hidden_stories`  WHERE `hidden_stories`.`user_id` = 1 AND 1=0[0m
D, [2016-01-05T10:31:30.260359 #2768] DEBUG -- :   [1m[35mKeystore Load (0.2ms)[0m  SELECT  `keystores`.* FROM `keystores`  WHERE `keystores`.`key` = 'user:1:unread_messages'  ORDER BY `keystores`.`key` ASC LIMIT 1
D, [2016-01-05T10:31:30.262390 #2768] DEBUG -- :   [1m[36m (0.2ms)[0m  [1mSELECT COUNT(*) FROM `invitation_requests`  WHERE `invitation_requests`.`is_verified` = 1[0m
