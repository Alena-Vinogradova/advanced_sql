/* Проект выполняется в интерактивном тренажере на платформе Яндекс.Практикума.
Состоит из двух частей на 20 задач на составление запросов к базе данных (PostgreSQL) StackOverFlow за 2008 год. */

/* 1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки». */

SELECT COUNT(posts.id)
FROM stackoverflow.posts 
WHERE post_type_id = 1 AND (favorites_count >= 100 OR score > 300);

/* 2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа. */

WITH t1 AS (SELECT creation_date::date, COUNT(*) AS amt
    	    FROM stackoverflow.posts 
            WHERE post_type_id = 1 AND (creation_date BETWEEN '2008-11-01' AND '2008-11-19')
            GROUP BY creation_date::date
            ORDER BY creation_date)

SELECT ROUND(AVG(amt))
FROM t1;

/* 3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей. */

SELECT COUNT(DISTINCT b.user_id)
FROM stackoverflow.badges AS b
JOIN stackoverflow.users AS u ON u.id = b.user_id
WHERE u.creation_date::date = b.creation_date::date;

/* 4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос? */

SELECT COUNT(DISTINCT p.id)
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON u.id = p.user_id
JOIN stackoverflow.votes v ON v.post_id = p.id
WHERE display_name = 'Joel Coehoorn';

/* 5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. 
Таблица должна быть отсортирована по полю id. */

SELECT*, 
      ROW_NUMBER() OVER (ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY id;

/* 6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. 
Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. 
Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя. */

SELECT u.id, 
       COUNT(v.id)
FROM stackoverflow.users u
JOIN stackoverflow.votes v ON v.user_id = u.id
JOIN stackoverflow.vote_types vt ON vt.id = v.vote_type_id
WHERE vt.name = 'Close'
GROUP BY u.id
ORDER BY COUNT(v.id) DESC, u.id desc
LIMIT 10;
      
/* 7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей: идентификатор пользователя, число значков, место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя. */

WITH t1 AS (SELECT u.id, COUNT(b.id) AS qty
	    FROM stackoverflow.users u
	    JOIN stackoverflow.badges b ON b.user_id = u.id
	    WHERE b.creation_date BETWEEN '2008-11-15' AND '2008-12-16'
	    GROUP BY u.id
            ORDER BY COUNT(b.id) DESC, u.id
            LIMIT 10)

SELECT *, 
       DENSE_RANK() OVER(ORDER BY qty DESC)
FROM t1;

/* 8. Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей: заголовок поста, идентификатор пользователя, число очков поста.
Cреднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков. */

SELECT title, 
       user_id, score, 
       ROUND(AVG(score) OVER (PARTITION BY user_id))
FROM stackoverflow.posts p
WHERE title IS NOT NULL AND score != 0;

/* 9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. 
Посты без заголовков не должны попасть в список. */

SELECT title
FROM stackoverflow.posts p
JOIN stackoverflow.users u ON u.id = p.user_id
JOIN stackoverflow.badges b ON b.user_id = u.id
WHERE title IS NOT NULL
GROUP BY title
HAVING COUNT(b.id) > 1000;

/* 10. Напишите запрос, который выгрузит данные о пользователях из США (англ. United States).
Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу. */

SELECT id, 
       views,
       CASE
           WHEN views >= 350 THEN 1
           WHEN views < 350 AND views >= 100 THEN 2
           WHEN views < 100 THEN 3
       END
FROM stackoverflow.users
WHERE location LIKE '%Canada%' AND (views != 0 OR views > 0);

/* 11. Дополните предыдущий запрос. 
Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
Выведите поля с идентификатором пользователя, группой и количеством просмотров. 
Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора. */

WITH t1 AS (SELECT id, 
                   views,
      		   CASE
          	       WHEN views >= 350 THEN 1
                       WHEN views < 350 AND views >= 100 THEN 2
                       WHEN views < 100 THEN 3
                   END AS group_
	    FROM stackoverflow.users
	    WHERE location LIKE '%Canada%' AND (views != 0 OR views > 0)),
     t2 AS (SELECT group_, 
		   MAX(views)
	    FROM t1
            GROUP BY group_)

SELECT id, 
       t1.group_,
       views
FROM t1
JOIN t2 ON t1.group_ = t2.group_
WHERE t1.views = t2.max AND t1.group_ = t2.group_
ORDER BY views DESC, id;

/* 12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. 
Сформируйте таблицу с полями: номер дня, число пользователей, зарегистрированных в этот день, сумму пользователей с накоплением. */

WITH t1 AS (SELECT EXTRACT(DAY FROM creation_date) AS day_,
 	           COUNT(id) amt 
	    FROM stackoverflow.users
	    WHERE EXTRACT(MONTH FROM creation_date) = 11 AND EXTRACT(YEAR FROM creation_date) = 2008
	    GROUP BY EXTRACT(DAY FROM creation_date))

SELECT *, 
       SUM(amt) OVER (ORDER BY day_)
FROM t1
ORDER BY day_;

/* 13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. 
Отобразите: идентификатор пользователя, разницу во времени между регистрацией и первым постом. */

WITH first_post AS (SELECT user_id,
	            creation_date,
		    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY creation_date)
		    FROM stackoverflow.posts),
     first_dt AS (SELECT user_id,
	                 MIN(creation_date) AS first_date
		  FROM first_post
		  GROUP BY user_id
		  ORDER BY user_id)

SELECT user_id,
       first_date - creation_date
FROM stackoverflow.users u
JOIN first_dt fd ON fd.user_id = u.id;


-- Вторая часть проекта --


/* 1. Выведите общую сумму просмотров постов за каждый месяц 2008 года. 
Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. 
Результат отсортируйте по убыванию общего количества просмотров. */

SELECT DATE_TRUNC('month', creation_date)::date AS month,
       SUM(views_count) AS ttl_view
FROM stackoverflow.posts
GROUP BY DATE_TRUNC('month', creation_date)::date
ORDER BY ttl_view DESC;

/* 2. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. 
Вопросы, которые задавали пользователи, не учитывайте. 
Для каждого имени пользователя выведите количество уникальных значений user_id. 
Отсортируйте результат по полю с именами в лексикографическом порядке. */

SELECT display_name,
       COUNT(DISTINCT posts.user_id)
FROM stackoverflow.posts
JOIN stackoverflow.post_types ON post_types.id = posts.post_type_id
JOIN stackoverflow.users ON users.id = posts.user_id
WHERE type = 'Answer' AND posts.creation_date::date BETWEEN users.creation_date::date AND (users.creation_date::date + INTERVAL '1 month')
GROUP BY display_name
HAVING COUNT(posts.id) > 100                 
ORDER BY display_name;

/* 3. Выведите количество постов за 2008 год по месяцам. 
Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. 
Отсортируйте таблицу по значению месяца по убыванию. */

SELECT DATE_TRUNC('month', p.creation_date)::date AS month,
       COUNT(p.id)
FROM stackoverflow.posts p
WHERE EXTRACT(YEAR FROM p.creation_date) = 2008 AND
      user_id IN (SELECT u.id
                  FROM stackoverflow.users u
                  JOIN stackoverflow.posts p ON p.user_id = u.id
                  WHERE EXTRACT(MONTH FROM u.creation_date) = 9 AND EXTRACT(MONTH FROM p.creation_date) = 12)

GROUP BY DATE_TRUNC('month', p.creation_date)::date
ORDER BY month DESC;

/* 4. Используя данные о постах, выведите несколько полей:
- идентификатор пользователя, который написал пост;
- дата создания поста;
- количество просмотров у текущего поста;
- сумму просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста. */

SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts;

/* 5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? 
Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. 
Нужно получить одно целое число — не забудьте округлить результат. */

WITH t1 AS (SELECT user_id,
	           COUNT(DISTINCT EXTRACT(DAY FROM creation_date)) AS day_cnt
	    FROM stackoverflow.posts
	    WHERE DATE_TRUNC('day',creation_date) BETWEEN '2008-12-01' AND '2008-12-07'
	    GROUP BY user_id)

SELECT ROUND(AVG(day_cnt))
FROM t1;

/* 6. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? 
Отобразите таблицу со следующими полями:
- номер месяца;
- количество постов за месяц;
- процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. 
Округлите значение процента до двух знаков после запятой. */

WITH t1 AS (SELECT EXTRACT(MONTH FROM creation_date) AS month,
	           COUNT(DISTINCT id) AS post_cnt
	    FROM stackoverflow.posts
	    WHERE DATE_TRUNC('month', creation_date) BETWEEN '2008-09-01' AND '2008-12-31'
	    GROUP BY month)

SELECT*,
      ROUND(((post_cnt::numeric/LAG(post_cnt) OVER (ORDER BY month)) - 1)*100,2)
FROM t1;

/* 7.Выгрузите данные активности пользователя, который опубликовал больше всего постов за всё время.
Выведите данные за октябрь 2008 года в таком виде:
- номер недели;
- дата и время последнего поста, опубликованного на этой неделе. */

WITH t1 AS (SELECT user_id, COUNT(id) AS id_amt
	    FROM stackoverflow.posts
	    GROUP BY user_id
	    ORDER BY id_amt DESC
	    LIMIT 1),
     t2 AS (SELECT posts.user_id, 
	    EXTRACT(WEEK FROM creation_date) AS week, 
	    creation_date
	    FROM stackoverflow.posts
	    JOIN t1 ON t1.user_id = posts.user_id
	    WHERE DATE_TRUNC('month', creation_date) = '2008-10-01' )

SELECT DISTINCT week,
       MAX(creation_date) OVER (PARTITION BY week) AS last_post
FROM t2;