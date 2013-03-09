# coding: utf-8

[
  { pt: 'Arte', en: 'Art', hk: 'Art'  },
  { pt: 'Artes plásticas', en: 'Visual Arts', hk: 'Visual Arts'  },
  { pt: 'Circo', en: 'Circus', hk: 'Circus' },
  { pt: 'Comunidade', en: 'Community', hk: 'Community' },
  { pt: 'Feito à mão', en: 'Handmade', hk: 'Handmade' },
  { pt: 'Humor', en: 'Humor', hk: 'Humor' },
  { pt: 'Quadrinhos', en: 'Comicbooks', hk: 'Comicbooks' },
  { pt: 'Dança', en: 'Dance', hk: 'Dance'  },
  { pt: 'Design', en: 'Design', hk: 'Design'  },
  { pt: 'Eventos', en: 'Events', hk: 'Events' },
  { pt: 'Moda', en: 'Fashion', hk: 'Fashion'  },
  { pt: 'Comida', en: 'Food', hk: 'Food' },
  { pt: 'Cinema & Vídeo', en: 'Film & Video', hk: 'Film & Video'  },
  { pt: 'Jogos', en: 'Games', hk: 'Games' },
  { pt: 'Jornalismo', en: 'Journalism', hk: 'Journalism'  },
  { pt: 'Música', en: 'Music', hk: 'Music' },
  { pt: 'Fotografia', en: 'Photography', hk: 'Photography' },
  { pt: 'Tecnologia', en: 'Technology', hk: 'Technology' },
  { pt: 'Teatro', en: 'Theatre', hk: 'Theatre' },
  { pt: 'Esporte', en: 'Sport', hk: 'Sport' },
  { pt: 'Graffiti', en: 'Graffiti', hk: 'Graffiti'  },
  { pt: 'Web', en: 'Web', hk: 'Web' },
  { pt: 'Carnaval', en: 'Carnival', hk: 'Carnival'  },
  { pt: 'Arquitetura & Urbanismo', en: 'Architecture & Urbanism', hk: 'Architecture & Urbanism'  },
  { pt: 'Literatura', en: 'Literature', hk: 'Literature'  }
].each do |name|
   category = Category.find_or_initialize_by_name_pt name[:pt]
   category.update_attributes({
     name_en: name[:en]
   })
   category.update_attributes({
     name_hk: name[:hk]
   })
 end

[
  'confirm_backer','payment_slip','project_success','backer_project_successful',
  'backer_project_unsuccessful','project_received','updates','project_unsuccessful',
  'project_visible','processing_payment','new_draft_project', 'project_rejected'
].each do |name|
  NotificationType.find_or_create_by_name name
end

{
  company_name: 'Pullwater',
  host: 'pullwater.com',
  base_url: "http://pullwater.com",
  blog_url: " http://pullwater.tumblr.com/",
  email_contact: 'contato@pullwater.com',
  email_payments: 'financeiro@pullwater.com',
  email_projects: 'projetos@pullwater.com',
  email_system: 'system@pullwater.com',
  email_no_reply: 'no-reply@pullwater.com',
  facebook_url: "http://facebook.com/pullwater",
  facebook_app_id: '427111090709356',
  twitter_username: "pullwaterhk",
  bitly_api_login: "pullwater",
  bitly_api_key: "R_60f3630aebaf46c793c00e3048255724",
  mailchimp_url: "http://pullwater.us6.list-manage.com/subscribe?u=394bd62853&id=60dfd14046&id=60dfd14046",
  catarse_fee: '0.13'
}.each do |name, value|
  Configuration.find_or_create_by_name name, value: value
end
